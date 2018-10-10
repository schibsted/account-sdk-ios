//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class UserAuthTests: QuickSpec {

    override func spec() {

        describe("Token exchange") {
            it("Should fail if logged out") {
                var stubSignup = NetworkStub(path: .path(Router.exchangeToken.path))
                stubSignup.returnData(json: .fromFile("token-exchange-valid"))
                stubSignup.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stubSignup)

                let user = TestingUser(state: .loggedOut)
                user.auth.oneTimeCode(clientID: ClientConfiguration.testing.clientID) { result in
                    expect(result).to(failWith(ClientError.invalidUser))
                }
            }

            it("Should return a code") {
                var stubSignup = NetworkStub(path: .path(Router.exchangeToken.path))
                stubSignup.returnData(json: .fromFile("token-exchange-valid"))
                stubSignup.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stubSignup)

                let user = TestingUser(state: .loggedIn)
                user.auth.oneTimeCode(clientID: ClientConfiguration.testing.clientID) { result in
                    guard case let .success(code) = result else {
                        return fail()
                    }
                    expect(code).to(equal("123"))
                }
            }

            it("Should refresh on invalid token") {
                let user = TestingUser(state: .loggedIn)

                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("valid-refresh"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                var wantedStub = NetworkStub(path: .path(Router.exchangeToken.path))
                wantedStub.returnData([
                    (data: .fromFile("token-invalid"), statusCode: 401),
                    (data: .fromFile("token-exchange-valid"), statusCode: 200),
                ])
                StubbedNetworkingProxy.addStub(wantedStub)

                user.auth.oneTimeCode(clientID: ClientConfiguration.testing.clientID) { result in
                    expect(result).to(beSuccess())
                }
            }

            describe("refreshRetryCount") {
                it("Should default to nil") {
                    let user = User(state: .loggedIn)
                    let userAuth = user.auth as? User.Auth
                    expect(userAuth?.nonDeprecatedRefreshRetryCount).to(beNil())
                    expect(userAuth?.refreshRetryCount).to(beNil())
                }
                
                it("Should be nil if set to nil") {
                    let user = User(state: .loggedIn)
                    let userAuth = user.auth as? User.Auth
                    userAuth?.refreshRetryCount = nil
                    expect(userAuth?.nonDeprecatedRefreshRetryCount) == -1
                    expect(userAuth?.refreshRetryCount).to(beNil())
                }
            }
        }
    }
}
