//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class NetworkingTests: QuickSpec {

    override func spec() {

        describe("send") {

            it("Should use any additional headers") {
                let headers = ["one": "two"]
                Networking.additionalHeaders = headers
                expect(Networking.additionalHeaders) == headers

                let url = URL(string: "https://whatever")!
                var stub = NetworkStub(path: .url(url))
                stub.returnResponse(status: 200)

                waitUntil { done in
                    Networking.send(to: url, using: .GET) { _, _, _ in
                        done()
                    }.resume()
                }

                expect(Networking.testingProxy.calls.first?.sentHTTPHeaders?["one"]) == "two"
            }

        }

        describe("stubbed networking proxy") {
            it("should not cache if cache control set and caching off") {
                let url = URL(string: "https://whatever")!
                let request = URLRequest(url: url)

                let stubbedProxy = StubbedNetworkingProxy()

                var stub = NetworkStub(path: .url(url))
                stub.returnResponse(status: 200, headers: [
                    "cache-control": "max-age=5",
                ])
                StubbedNetworkingProxy.addStub(stub)

                let config = URLSessionConfiguration.default
                config.urlCache = nil
                let session = URLSession(configuration: config)

                waitUntil { done in
                    stubbedProxy.dataTask(for: session, request: request) { _, _, _ in
                        done()
                    }.resume()
                }

                let response = session.configuration.urlCache?.cachedResponse(for: request)
                expect(response).to(beNil())
            }

            it("should cache if cache control set and caching on") {
                let url = URL(string: "https://whatever")!
                let request = URLRequest(url: url)

                let stubbedProxy = StubbedNetworkingProxy()

                var stub = NetworkStub(path: .url(url))
                stub.returnResponse(status: 200, headers: [
                    "cache-control": "max-age=5",
                ])
                StubbedNetworkingProxy.addStub(stub)

                let config = URLSessionConfiguration.default
                config.requestCachePolicy = .useProtocolCachePolicy
                config.urlCache = URLCache.shared
                let session = URLSession(configuration: config)

                waitUntil { done in
                    stubbedProxy.dataTask(for: session, request: request) { _, _, _ in
                        done()
                    }.resume()
                }

                let response = session.configuration.urlCache?.cachedResponse(for: request)
                expect(response).toNot(beNil())
            }
        }

        describe("default networking proxy") {

            it("should not cache responses") {
                Networking.proxy = StubbedNetworkingProxy()
                let defafaultNetworkingProxy = DefaultNetworkingProxy()
                let request = URLRequest(url: URL(string: "https://whatever")!)

                var stub = NetworkStub(path: .path("https://whatever"))
                stub.returnResponse(status: 200, headers: [
                    "cache-control": "max-age=5",
                ])
                StubbedNetworkingProxy.addStub(stub)

                waitUntil { done in
                    Networking.dataTask(for: defafaultNetworkingProxy.session, request: request) { _, _, _ in
                        done()
                    }.resume()
                }

                let response = defafaultNetworkingProxy.session.configuration.urlCache?.cachedResponse(for: request)
                expect(response).to(beNil())
            }
        }
    }
}
