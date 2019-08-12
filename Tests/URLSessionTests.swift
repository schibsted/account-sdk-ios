//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

func doDataTask(
    _ session: URLSession,
    request: URLRequest,
    completion: @escaping URLSessionTaskCallback = { _, _, _ in }
) {
    let maybeResult = Atomic<(data: Data?, response: URLResponse?, error: Error?)?>(nil)
    waitUntil { done in
        session.dataTask(with: request) { data, response, error in
            maybeResult.value = (data, response, error)
            done()
        }.resume()
    }
    if let result = maybeResult.value {
        completion(result.data, result.response, result.error)
    }
}

func doDataTask(
    _ session: URLSession,
    url: URL,
    completion: @escaping URLSessionTaskCallback = { _, _, _ in }
) {
    doDataTask(session, request: URLRequest(url: url), completion: completion)
}

class HTTPSessionSharedExamplesConfiguration: QuickConfiguration {
    override class func configure(_: Configuration) {
        sharedExamples("refresh failure") { (context: SharedExampleContext) in

            let status = context()["status"] as! Int
            let logout = context()["logout"] as! Bool

            let extraDescription = "and \(logout ? "" : "not ")logout"

            it("Should cancel requests after status \(status) \(extraDescription)") {
                let (session, user) = Utils.makeURLSession()

                let wantedUrl = "http://www.example.com/"

                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnResponse(status: status)
                stub.returnData(json: .fromFile("empty"))
                StubbedNetworkingProxy.addStub(stub)

                let numTasks = 100
                var stubWanted = NetworkStub(path: .path(wantedUrl))
                stubWanted.returnResponse(status: 401)
                StubbedNetworkingProxy.addStub(stubWanted)

                let doneCounter = AtomicInt(0)
                let tasks = SynchronizedArray<URLSessionTask>()
                waitUntil { done in
                    for i in 0..<numTasks {
                        let task = session.dataTask(with: URL(string: wantedUrl + String(i))!) { _, _, error in
                            expect(error).to(
                                satisfyAnyOf(
                                    matchError(ClientError.userRefreshFailed(kDummyError)),
                                    matchError(ClientError.invalidUser)
                                )
                            )
                            doneCounter.getAndIncrement()
                            if doneCounter.value == numTasks {
                                done()
                            }
                        }
                        tasks.append(task)
                    }

                    tasks.data.forEach { $0.resume() }
                }

                for task in tasks.data {
                    expect(task.state).toEventually(equal(URLSessionTask.State.completed))
                }

                expect(user.state).to(logout ? equal(UserState.loggedOut) : equal(UserState.loggedIn))
            }
        }
    }
}

class URLSessionTests: QuickSpec {

    override func spec() {

        describe("URLSession") {
            it("Should have access token set in authorization header") {
                let (session, user) = Utils.makeURLSession()
                Utils.hold(user)
                let userObjectValue = String(describing: ObjectIdentifier(user).hashValue)
                let authHeader = session.configuration.httpAdditionalHeaders?[AutoRefreshURLProtocol.key] as? String
                expect(authHeader).to(equal(userObjectValue))
            }

            it("Should create task in suspended state") {
                let session = Utils.makeURLSession().session
                let task = session.dataTask(with: URL(string: "example.com")!)
                expect(task.state).to(equal(URLSessionTask.State.suspended))
            }

            it("Should perform a standard data task") {
                let (session, user) = Utils.makeURLSession()
                Utils.hold(user)

                let url = URL(string: "example.com")!
                var stub = NetworkStub(path: .url(url))
                stub.returnData(json: ["key": "prissy brat"])
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                doDataTask(session, url: URL(string: "example.com")!) { data, _, _ in
                    expect(String(data: data!, encoding: .utf8)) == "{\"key\":\"prissy brat\"}"
                }
            }

            it("Should handle network error") {
                let expectedError = NSError(domain: "getting jiggy with it", code: 19_212_701, userInfo: nil)
                let url = URL(string: "http://www.example.com/")!
                var stub = NetworkStub(path: .url(url))
                stub.returnError(error: expectedError)
                StubbedNetworkingProxy.addStub(stub)

                let (session, user) = Utils.makeURLSession()
                Utils.hold(user)
                doDataTask(session, url: url) { _, _, error in
                    expect(error!).to(matchError(expectedError))
                }
            }

            it("Should update internal URLSession after refresh") {
                let (session, user) = Utils.makeURLSession()
                Utils.hold(user)

                let url = URL(string: "example.com")!
                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("valid-refresh"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                var wantedStub = NetworkStub(path: .url(url))
                wantedStub.returnData([
                    (data: .fromFile("empty"), statusCode: 401),
                    (data: "".data(using: .utf8) ?? Data(), statusCode: 200),
                ])
                StubbedNetworkingProxy.addStub(wantedStub)

                doDataTask(session, url: url)
                expect(Networking.testingProxy.requests.count) == 3
                let call0Headers = Networking.testingProxy.requests.data[0].request?.allHTTPHeaderFields
                let call2Headers = Networking.testingProxy.requests.data[2].request?.allHTTPHeaderFields
                expect(call0Headers?["Authorization"]).to(equal("Bearer testAccessToken"))
                expect(call2Headers?["Authorization"]).to(equal("Bearer 123"))
            }

            it("Should do an automatic refresh") {
                let (session, user) = Utils.makeURLSession()

                let wantedUrl = "example.com"
                let successData = "i am google"

                let url = URL(string: wantedUrl)!
                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("valid-refresh"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                var wantedStub = NetworkStub(path: .url(url))
                wantedStub.returnData([
                    (data: .fromFile("empty"), statusCode: 401),
                    (data: successData.data(using: .utf8) ?? Data(), statusCode: 200),
                ])
                StubbedNetworkingProxy.addStub(wantedStub)

                doDataTask(session, url: URL(string: wantedUrl)!) { data, _, _ in
                    expect(String(data: data!, encoding: .utf8)).to(equal(successData))
                }

                expect(Networking.testingProxy.requests.count).to(equal(3))
                guard Networking.testingProxy.requests.count == 3 else { return }
                let call1 = Networking.testingProxy.requests.data[0]
                let call2 = Networking.testingProxy.requests.data[1]
                let call3 = Networking.testingProxy.requests.data[2]
                expect(call1.url?.absoluteString).to(equal(wantedUrl))
                expect(call2.url?.absoluteString).to(contain(Router.oauthToken.path))
                expect(call3.url?.absoluteString).to(equal(wantedUrl))
                expect(user.tokens?.refreshToken).to(equal("abc"))
            }

            it("Should handle butt loads of requests") {
                let (session, user) = Utils.makeURLSession()
                SDKConfiguration.shared.refreshRetryCount = nil // don't error on refresh retries
                Utils.hold(user)

                let wantedUrl = "http://www.example.com/"
                let refreshUrl = "/oauth/token"

                var refreshStub = NetworkStub(path: .path(refreshUrl))
                refreshStub.returnData(json: .fromFile("valid-refresh"))
                refreshStub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(refreshStub)

                let numRequestsToFire = 100

                var wantedStub = NetworkStub(path: .path(wantedUrl))
                let failure = (data: "oh noes".data(using: .utf8) ?? Data(), statusCode: 401)
                let success = (data: "potatoes".data(using: .utf8) ?? Data(), statusCode: 200)
                var requests = [failure]
                // Alternate between a builder that returns 401 and 200.
                for i in 0..<numRequestsToFire {
                    requests.append(i % 2 == 0 ? failure : success)
                }
                wantedStub.returnData(requests)
                StubbedNetworkingProxy.addStub(wantedStub)

                let tasks = SynchronizedArray<URLSessionTask>()
                let doneCounter = AtomicInt(0)
                waitUntil { done in
                    for i in 0..<numRequestsToFire {
                        let task = session.dataTask(with: URL(string: wantedUrl + String(i))!) { data, _, _ in
                            if let data = data, let string = String(data: data, encoding: .utf8), string == "potatoes" {
                                doneCounter.getAndIncrement()
                            }
                            if doneCounter.value == numRequestsToFire {
                                done()
                            }
                        }
                        tasks.append(task)
                        task.resume()
                    }
                }

                tasks.data.forEach { expect($0.state).to(equal(URLSessionTask.State.completed)) }

                expect(doneCounter.value).to(equal(numRequestsToFire))
            }

            it("should fail if refresh retry count exeeded") {
                let wantedUrl = "http://www.example.com/"
                let refreshUrl = Router.oauthToken.path

                var stub = NetworkStub(path: .url(URL(string: "http://www.example.com/")!))
                stub.returnResponse(status: 401)
                StubbedNetworkingProxy.addStub(stub)

                var stubSignup = NetworkStub(path: .path(Router.oauthToken.path))
                stubSignup.returnData(json: .fromFile("valid-refresh"))
                stubSignup.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stubSignup)

                let (session, user) = Utils.makeURLSession()
                SDKConfiguration.shared.refreshRetryCount = 2
                doDataTask(session, url: URL(string: wantedUrl)!) { _, _, error in
                    expect(error).to(matchError(ClientError.userRefreshFailed(kDummyError)))
                    guard let clientError = error as? ClientError, case let ClientError.userRefreshFailed(error) = clientError else {
                        return fail()
                    }
                    expect((error as NSError).code) == ClientError.RefreshRetryExceededCode
                }
                expect(Networking.testingProxy.requests.count).to(equal(5))
                guard Networking.testingProxy.requests.count == 5 else { return }
                expect(Networking.testingProxy.requests.data[0].url?.absoluteString).to(equal(wantedUrl))
                expect(Networking.testingProxy.requests.data[1].url?.absoluteString).to(contain(refreshUrl))
                expect(Networking.testingProxy.requests.data[2].url?.absoluteString).to(equal(wantedUrl))
                expect(Networking.testingProxy.requests.data[3].url?.absoluteString).to(contain(refreshUrl))
                expect(Networking.testingProxy.requests.data[4].url?.absoluteString).to(equal(wantedUrl))
                expect(user.tokens?.refreshToken).to(equal("abc"))
            }

            itBehavesLike("refresh failure") { ["status": 400, "logout": true] }
            itBehavesLike("refresh failure") { ["status": 401, "logout": true] }
            itBehavesLike("refresh failure") { ["status": 403, "logout": true] }
            itBehavesLike("refresh failure") { ["status": 500, "logout": false] }
            itBehavesLike("refresh failure") { ["status": 300, "logout": false] }
        }
    }
}
