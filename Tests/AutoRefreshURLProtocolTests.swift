//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class AutoRefreshURLProtocolTests: QuickSpec {

    let prissyBrat = "prissy brat"
    func addPrissyBratStub() {
        let url = URL(string: "example.com")!
        var stub = NetworkStub(path: .url(url))
        stub.returnData(string: self.prissyBrat)
        StubbedNetworkingProxy.addStub(stub)
    }

    override func spec() {

        it("Should perform a standard data task") {
            self.addPrissyBratStub()

            let user = TestingUser(state: .loggedIn)
            let session = URLSession(user: user, configuration: .default)
            let request = URLRequest(url: URL(string: "example.com")!)

            waitUntil { done in
                let task = session.dataTask(with: request) { data, _, _ in
                    expect(String(data: data!, encoding: .utf8)) == self.prissyBrat
                    done()
                }

                expect(task.currentRequest?.allHTTPHeaderFields?[Networking.Header.userAgent.rawValue]).to(beNil())
                expect(task.currentRequest?.allHTTPHeaderFields?[Networking.Header.xSchibstedAccountUserAgent.rawValue]) == UserAgent().value

                task.resume()
            }

            waitUntil { [unowned user] done in
                user.wrapped.taskManager.waitForRequestsToFinish()
                done()
            }
        }

        it("Should fail if no user") {
            self.addPrissyBratStub()

            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses = [AutoRefreshURLProtocol.self]
            let session = URLSession(configuration: configuration)
            let request = URLRequest(url: URL(string: "http://example.com")!)

            waitUntil { done in
                let task = session.dataTask(with: request) { _, _, error in
                    expect(error).to(matchError(ClientError.invalidUser))
                    done()
                }
                task.resume()
            }
        }

        it("Should fail if user dies") {
            let session: URLSession?
            do {
                let user = TestingUser(state: .loggedIn)
                let configuration = URLSessionConfiguration.default
                configuration.protocolClasses = [AutoRefreshURLProtocol.self]
                session = URLSession(user: user, configuration: URLSessionConfiguration.default)
            }

            self.addPrissyBratStub()
            let request = URLRequest(url: URL(string: "http://example.com")!)

            waitUntil { done in
                let task = session?.dataTask(with: request) { _, _, error in
                    expect(error).to(matchError(ClientError.invalidUser))
                    done()
                }
                task?.resume()
            }
        }

        it("Should have access token in request") {
            self.addPrissyBratStub()

            let user = User(state: .loggedIn)
            let session = URLSession(user: user, configuration: .default)
            let request = URLRequest(url: URL(string: "http://example.com")!)
            waitUntil { done in
                session.dataTask(with: request) { _, _, _ in done() }.resume()
            }
            expect(Networking.testingProxy.requests.data[0].request?.allHTTPHeaderFields?["Authorization"]).to(contain("testAccessToken"))
        }

        it("Should refresh on 401") {
            let wantedUrl = "example.com"
            let refreshUrl = "/oauth/token"
            let successData = "i am not google"

            var refreshStub = NetworkStub(path: .path(refreshUrl))
            refreshStub.returnData(json: .fromFile("valid-refresh"))
            refreshStub.returnResponse(status: 200)
            StubbedNetworkingProxy.addStub(refreshStub)

            var wantedStub = NetworkStub(path: .path(wantedUrl))
            wantedStub.returnData([
                (data: .fromFile("empty"), statusCode: 401),
                (data: successData.data(using: .utf8) ?? Data(), statusCode: 200),
            ])
            StubbedNetworkingProxy.addStub(wantedStub)

            let user = User(state: .loggedIn)
            let session = URLSession(user: user, configuration: .default)
            let request = URLRequest(url: URL(string: wantedUrl)!)

            waitUntil { done in
                let task = session.dataTask(with: request) { data, _, _ in
                    expect(String(data: data!, encoding: .utf8)) == successData
                    done()
                }
                task.resume()
            }

            expect(Networking.testingProxy.requests.count).to(equal(3))
            guard Networking.testingProxy.requests.count > 2 else { return }
            let call1 = Networking.testingProxy.requests.data[0]
            let call2 = Networking.testingProxy.requests.data[1]
            let call3 = Networking.testingProxy.requests.data[2]
            expect(call1.url?.absoluteString).to(equal(wantedUrl))
            expect(call2.url?.absoluteString.contains(refreshUrl)).to(beTrue())
            expect(call3.url?.absoluteString).to(equal(wantedUrl))

            expect(user.tokens?.refreshToken).to(equal("abc"))

            waitUntil { [unowned user] done in
                user.taskManager.waitForRequestsToFinish()
                done()
            }
        }

        it("Should not refresh on 200") {
            let wantedUrl = "example.com"
            self.addPrissyBratStub()

            let user = User(state: .loggedIn)
            let session = URLSession(user: user, configuration: .default)
            let request = URLRequest(url: URL(string: wantedUrl)!)

            waitUntil { done in
                let task = session.dataTask(with: request) { data, _, _ in
                    expect(String(data: data!, encoding: .utf8)) == self.prissyBrat
                    done()
                }
                task.resume()
            }

            expect(Networking.testingProxy.requests.count).to(equal(1))
            let call1 = Networking.testingProxy.requests.data[0]
            expect(call1.url?.absoluteString).to(equal(wantedUrl))
            expect(user.tokens?.refreshToken).to(equal("testRefreshToken"))

            waitUntil { [unowned user] done in
                user.taskManager.waitForRequestsToFinish()
                done()
            }
        }

        it("Should handle network error") {
            let expectedError = NSError(domain: "getting jiggy with it", code: 501, userInfo: nil)
            let url = URL(string: "example.com")!
            var stub = NetworkStub(path: .url(url))
            stub.returnError(error: expectedError)
            stub.returnResponse(status: 501)
            StubbedNetworkingProxy.addStub(stub)

            let user = TestingUser(state: .loggedIn)
            let session = URLSession(user: user, configuration: URLSessionConfiguration.default)

            waitUntil { done in
                let task = session.dataTask(with: URLRequest(url: url)) { _, _, error in
                    expect(error).to(matchError(expectedError))
                    done()
                }
                task.resume()
            }
        }

        it("Should handle butt loads of requests") {

            let wantedUrl = "http://www.example.com/"
            let refreshUrl = "/oauth/token"

            var refreshStub = NetworkStub(path: .path(refreshUrl))
            refreshStub.returnData(json: .fromFile("valid-refresh"))
            refreshStub.returnResponse(status: 200)
            StubbedNetworkingProxy.addStub(refreshStub)

            let numRequestsToFire = 100

            var wantedStub = NetworkStub(path: .path(wantedUrl))
            let failure = (data: Data.fromFile("empty"), statusCode: 401)
            let success = (data: "potatoes".data(using: .utf8) ?? Data(), statusCode: 200)
            var requests = [failure]
            // Alternate between a builder that returns 401 and 200.
            for i in 0..<numRequestsToFire {
                requests.append(i % 2 == 0 ? failure : success)
            }
            requests.append(success)
            wantedStub.returnData(requests)
            StubbedNetworkingProxy.addStub(wantedStub)

            let user = TestingUser(state: .loggedIn)
            let session = URLSession(user: user, configuration: URLSessionConfiguration.default)

            SDKConfiguration.shared.refreshRetryCount = nil

            let tasks = SynchronizedArray<URLSessionTask>()
            let doneCounter = AtomicInt(0)
            waitUntil { done in
                for i in 0..<numRequestsToFire {
                    let request = URLRequest(url: URL(string: wantedUrl + String(i))!)
                    let task = session.dataTask(with: request) { data, _, _ in
                        if let data = data, let string = String(data: data, encoding: String.Encoding.utf8), string == "potatoes" {
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

            waitUntil { [unowned user] done in
                user.wrapped.taskManager.waitForRequestsToFinish()
                done()
            }

            expect(doneCounter.value).to(equal(numRequestsToFire))
        }

        it("Should handle refresh failure") {
            let url = URL(string: "example.com")!
            var stub = NetworkStub(path: .path("/oauth/token"))
            stub.returnResponse(status: 401)
            StubbedNetworkingProxy.addStub(stub)

            var stub2 = NetworkStub(path: .url(url))
            stub2.returnResponse(status: 401)
            StubbedNetworkingProxy.addStub(stub2)

            let user = TestingUser(state: .loggedIn)
            let session = URLSession(user: user, configuration: URLSessionConfiguration.default)
            waitUntil { done in
                session.dataTask(with: URLRequest(url: url)) {
                    expect($2).to(matchError(ClientError.userRefreshFailed(kDummyError)))
                    done()
                }.resume()
            }
        }

        it("Should handle cancel") {
            var refreshStub = NetworkStub(path: .path("example.com"))
            refreshStub.returnData(json: .fromFile("empty"))
            refreshStub.returnResponse(status: 200)
            StubbedNetworkingProxy.addStub(refreshStub)

            let user = TestingUser(state: .loggedIn)
            let session = URLSession(user: user, configuration: URLSessionConfiguration.default)
            waitUntil { done in
                let task = session.dataTask(with: URLRequest(url: URL(string: "https://www.example.com")!)) {
                    let error = $2 as NSError?
                    expect(error?.code).to(equal(NSURLErrorCancelled))
                    done()
                }
                task.resume()
                task.cancel()
            }
        }

        it("should cache responses from URLProtocol") {
            let wantedUrl = "https://example.com"
            let refreshUrl = "/oauth/token"
            let successData = "i am google"

            var refreshStub = NetworkStub(path: .path(refreshUrl))
            refreshStub.returnData(json: .fromFile("valid-refresh"))
            refreshStub.returnResponse(status: 200)
            StubbedNetworkingProxy.addStub(refreshStub)

            var wantedStub = NetworkStub(path: .path(wantedUrl))
            wantedStub.returnData([
                (data: .fromFile("empty"), statusCode: 401),
                (data: successData.data(using: .utf8) ?? Data(), statusCode: 200),
            ])
            StubbedNetworkingProxy.addStub(wantedStub)

            let user = TestingUser(state: .loggedIn)
            let session = URLSession(user: user, configuration: URLSessionConfiguration.default)
            let request = URLRequest(url: URL(string: wantedUrl)!)

            let cache = session.configuration.urlCache
            cache?.removeAllCachedResponses()

            waitUntil { done in
                let task = session.dataTask(with: request) { _, _, _ in
                    done()
                }

                task.resume()
            }

            expect(cache).toNot(beNil())
            let response = cache?.cachedResponse(for: request)
            expect(response).toNot(beNil())
            expect(String(data: response!.data, encoding: .utf8)).to(equal(successData))
        }

        it("should not cache responses from URLProtocol when client don't want caching") {
            let wantedUrl = "https://example.com"
            let refreshUrl = "/oauth/token"
            let successData = "i am google"

            var refreshStub = NetworkStub(path: .path(refreshUrl))
            refreshStub.returnData(json: .fromFile("valid-refresh"))
            refreshStub.returnResponse(status: 200)
            StubbedNetworkingProxy.addStub(refreshStub)

            var wantedStub = NetworkStub(path: .path(wantedUrl))
            wantedStub.returnData([
                (data: .fromFile("empty"), statusCode: 401),
                (data: successData.data(using: .utf8) ?? Data(), statusCode: 200),
            ])
            StubbedNetworkingProxy.addStub(wantedStub)

            let user = TestingUser(state: .loggedIn)
            let config = URLSessionConfiguration.default
            config.urlCache?.removeAllCachedResponses()
            config.urlCache = nil
            let session = URLSession(user: user, configuration: config)
            let request = URLRequest(url: URL(string: wantedUrl)!)

            waitUntil { done in
                let task = session.dataTask(with: request) { _, _, _ in
                    done()
                }

                task.resume()
            }

            // Since the user has set the urlCache to nil the response should not be cached.
            // Checking the default cache to see if the response was cached or not.
            let response = URLSessionConfiguration.default.urlCache?.cachedResponse(for: request)
            expect(response).to(beNil())
        }

        it("uploadtask refresh on 401") {
            let wantedUrl = "example.com"
            let refreshUrl = "/oauth/token"
            let successData = "i am not google"

            var refreshStub = NetworkStub(path: .path(refreshUrl))
            refreshStub.returnData(json: .fromFile("valid-refresh"))
            refreshStub.returnResponse(status: 200)
            StubbedNetworkingProxy.addStub(refreshStub)

            var wantedStub = NetworkStub(path: .path(wantedUrl))
            wantedStub.returnData([
                (data: .fromFile("empty"), statusCode: 401),
                (data: successData.data(using: .utf8) ?? Data(), statusCode: 200),
            ])
            StubbedNetworkingProxy.addStub(wantedStub)

            let user = TestingUser(state: .loggedIn)
            let session = URLSession(user: user, configuration: .default)
            let request = URLRequest(url: URL(string: wantedUrl)!)

            waitUntil { done in
                let task = session.uploadTask(with: request, from: Data(), completionHandler: { data, _, _ in
                    expect(String(data: data!, encoding: .utf8)) == successData
                    done()
                })

                task.resume()
            }

            expect(Networking.testingProxy.requests.count).to(equal(3))
            guard Networking.testingProxy.requests.count > 2 else { return }
            let call1 = Networking.testingProxy.requests.data[0]
            let call2 = Networking.testingProxy.requests.data[1]
            let call3 = Networking.testingProxy.requests.data[2]
            expect(call1.url?.absoluteString).to(equal(wantedUrl))
            expect(call2.url?.absoluteString.contains(refreshUrl)).to(beTrue())
            expect(call3.url?.absoluteString).to(equal(wantedUrl))
            expect(user.wrapped.tokens?.refreshToken).to(equal("abc"))
        }

        it("downloadtask refresh on 401") {
            let wantedUrl = "example.com"
            let refreshUrl = "/oauth/token"
            let successData = "i am google"

            var refreshStub = NetworkStub(path: .path(refreshUrl))
            refreshStub.returnData(json: .fromFile("valid-refresh"))
            refreshStub.returnResponse(status: 200)
            StubbedNetworkingProxy.addStub(refreshStub)

            var wantedStub = NetworkStub(path: .path(wantedUrl))
            wantedStub.returnData([
                (data: .fromFile("empty"), statusCode: 401),
                (data: successData.data(using: .utf8) ?? Data(), statusCode: 200),
            ])
            StubbedNetworkingProxy.addStub(wantedStub)

            let user = TestingUser(state: .loggedIn)
            let session = URLSession(user: user, configuration: URLSessionConfiguration.default)
            let request = URLRequest(url: URL(string: wantedUrl)!)

            waitUntil { done in
                let task = session.downloadTask(with: request, completionHandler: { url, _, _ in
                    expect(String(data: try! Data(contentsOf: url!), encoding: .utf8)) == successData
                    done()
                })
                task.resume()
            }

            expect(Networking.testingProxy.requests.count).to(equal(3))
            guard Networking.testingProxy.requests.count > 2 else { return }
            let call1 = Networking.testingProxy.requests.data[0]
            let call2 = Networking.testingProxy.requests.data[1]
            let call3 = Networking.testingProxy.requests.data[2]
            expect(call1.url?.absoluteString).to(equal(wantedUrl))
            expect(call2.url?.absoluteString.contains(refreshUrl)).to(beTrue())
            expect(call3.url?.absoluteString).to(equal(wantedUrl))
            expect(user.wrapped.tokens?.refreshToken).to(equal("abc"))
        }
    }
}
