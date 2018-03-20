//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Mockingjay
import Nimble
import Quick
@testable import SchibstedAccount

func doDataTask(
    _ session: URLSession,
    request: URLRequest,
    completion: @escaping URLSessionTaskCallback = { _, _, _ in }
) {
    var maybeResult: (data: Data?, response: URLResponse?, error: Error?)?
    waitUntil { done in
        session.dataTask(with: request) { data, response, error in
            maybeResult = (data, response, error)
            done()
        }.resume()
    }
    if let result = maybeResult {
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
            let xctest = context()["xctest"] as! XCTest
            let logout = context()["logout"] as! Bool

            let extraDescription = "and \(logout ? "not " : "")logout"

            it("Should cancel requests after status \(status) \(extraDescription)") {

                let (session, user) = Utils.makeURLSession()

                let wantedUrl = "http://www.example.com/"
                let refreshUrl = "/oauth/token"

                xctest.stub(uri(refreshUrl), Builders.load(string: "", status: status))
                xctest.stub({ $0.url?.host == "www.example.com" }, Builders.load(string: "", status: 401))

                let numTasks = 100

                var doneCounter = 0
                var tasks: [URLSessionTask] = []
                waitUntil { done in
                    for i in 0..<numTasks {
                        let task = session.dataTask(with: URL(string: wantedUrl + String(i))!) { _, _, error in
                            expect(error).to(matchError(ClientError.userRefreshFailed(kDummyError)))
                            doneCounter += 1
                            if doneCounter == numTasks {
                                done()
                            }
                        }
                        tasks.append(task)
                    }

                    tasks.forEach { $0.resume() }
                }

                for task in tasks {
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
                self.stub(uri("/oauth/token"), try! Builders.load(file: "valid-refresh", status: 200))
                self.stub(uri("example.com"), Builders.sequentialBuilder([
                    try! Builders.load(file: "empty", status: 401),
                    Builders.load(string: "", status: 200),
                ]))
                doDataTask(session, url: URL(string: "example.com")!)
                expect(Networking.testingProxy.callCount) == 3
                let call0Headers = Networking.testingProxy.calls[0].passedRequest?.allHTTPHeaderFields
                let call2Headers = Networking.testingProxy.calls[2].passedRequest?.allHTTPHeaderFields
                expect(call0Headers?["Authorization"]).to(equal("Bearer testAccessToken"))
                expect(call2Headers?["Authorization"]).to(equal("Bearer 123"))
            }

            it("Should do an automatic refresh") {
                let (session, user) = Utils.makeURLSession()

                let wantedUrl = "example.com"
                let refreshUrl = "/oauth/token"
                let successData = "i am google"

                self.stub(uri(refreshUrl), try! Builders.load(file: "valid-refresh", status: 200))

                self.stub(uri(wantedUrl), Builders.sequentialBuilder([
                    try! Builders.load(file: "empty", status: 401),
                    Builders.load(string: successData, status: 200),
                ]))

                doDataTask(session, url: URL(string: wantedUrl)!) { data, _, _ in
                    expect(String(data: data!, encoding: .utf8)).to(equal(successData))
                }

                expect(Networking.testingProxy.callCount).to(equal(3))
                guard Networking.testingProxy.calls.count == 3 else { return }
                let call1 = Networking.testingProxy.calls[0]
                let call2 = Networking.testingProxy.calls[1]
                let call3 = Networking.testingProxy.calls[2]
                expect(call1.passedUrl?.absoluteString).to(equal(wantedUrl))
                expect(call2.passedUrl?.absoluteString).to(contain(refreshUrl))
                expect(call3.passedUrl?.absoluteString).to(equal(wantedUrl))
                expect(user.tokens?.refreshToken).to(equal("abc"))
            }

            it("Should handle butt loads of requests") {
                let (session, user) = Utils.makeURLSession()
                user.auth.refreshRetryCount = nil // don't error on refresh retries
                Utils.hold(user)

                let wantedUrl = "http://www.example.com/"
                let refreshUrl = "/oauth/token"

                self.stub(uri(refreshUrl), try! Builders.load(file: "valid-refresh", status: 200))

                let numRequestsToFire = 100

                let failure = Builders.load(string: "oh noes", status: 401)
                let success = Builders.load(string: "potatoes", status: 200)
                var builders = [failure] // Make first one fail

                // Alternate between a builder that returns 401 and 200.
                for i in 0..<numRequestsToFire {
                    builders.append(i % 2 == 0 ? failure : success)
                }
                // Since the last builder provided is repeated until we run out of requests, make sure
                // that it's a success value. Else we go in a forever failure situation
                builders.append(success)

                self.stub({ $0.url?.host == "www.example.com" }, Builders.sequentialBuilder(builders))

                var tasks: [URLSessionTask] = []
                var doneCounter = 0
                waitUntil { done in
                    for i in 0..<numRequestsToFire {
                        let task = session.dataTask(with: URL(string: wantedUrl + String(i))!) { data, _, _ in
                            if let data = data, let string = String(data: data, encoding: .utf8), string == "potatoes" {
                                doneCounter += 1
                            }
                            if doneCounter == numRequestsToFire {
                                done()
                            }
                        }
                        tasks.append(task)
                        task.resume()
                    }
                }

                tasks.forEach { expect($0.state).to(equal(URLSessionTask.State.completed)) }

                expect(doneCounter).to(equal(numRequestsToFire))
            }

            it("should fail if refresh retry count exeeded") {
                let wantedUrl = "http://www.example.com/"
                let refreshUrl = Router.oauthToken.path

                var stub = NetworkStub(path: .url(URL(string: "http://www.example.com/")!))
                stub.returnResponse(status: 401)
                StubbedNetworkingProxy.addStub(stub)

                var stubSignup = NetworkStub(path: .path(Router.oauthToken.path))
                stubSignup.returnFile(file: "valid-refresh", type: "json", in: Bundle(for: TestingUser.self))
                stubSignup.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stubSignup)

                let (session, user) = Utils.makeURLSession()
                user.auth.refreshRetryCount = 2
                doDataTask(session, url: URL(string: wantedUrl)!) { _, _, error in
                    expect(error).to(matchError(ClientError.userRefreshFailed(kDummyError)))
                    guard let clientError = error as? ClientError, case let ClientError.userRefreshFailed(error) = clientError else {
                        return fail()
                    }
                    expect((error as NSError).code) == ClientError.RefreshRetryExceededCode
                }
                expect(Networking.testingProxy.callCount).to(equal(5))
                guard Networking.testingProxy.calls.count == 5 else { return }
                expect(Networking.testingProxy.calls[0].passedUrl?.absoluteString).to(equal(wantedUrl))
                expect(Networking.testingProxy.calls[1].passedUrl?.absoluteString).to(contain(refreshUrl))
                expect(Networking.testingProxy.calls[2].passedUrl?.absoluteString).to(equal(wantedUrl))
                expect(Networking.testingProxy.calls[3].passedUrl?.absoluteString).to(contain(refreshUrl))
                expect(Networking.testingProxy.calls[4].passedUrl?.absoluteString).to(equal(wantedUrl))
                expect(user.tokens?.refreshToken).to(equal("abc"))
            }

            itBehavesLike("refresh failure") { ["xctest": self, "status": 400, "logout": true] }
            itBehavesLike("refresh failure") { ["xctest": self, "status": 401, "logout": true] }
            itBehavesLike("refresh failure") { ["xctest": self, "status": 403, "logout": true] }
            itBehavesLike("refresh failure") { ["xctest": self, "status": 500, "logout": false] }
            itBehavesLike("refresh failure") { ["xctest": self, "status": 300, "logout": false] }
        }
    }
}
