//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class UserAgreementsTests: QuickSpec {

    override func spec() {

        describe("Agreements status") {
            it("Should fail if logged out") {
                let user = TestingUser(state: .loggedOut)
                user.agreements.status { result in
                    expect(result).to(failWith(ClientError.invalidUser))
                }
            }

            it("Should fetch unaccepted status") {
                let user = TestingUser(state: .loggedIn)
                var stubSignup = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                stubSignup.returnData(json: JSONObject.fromFile("agreements-valid-unaccepted"))
                stubSignup.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stubSignup)

                user.agreements.status { result in
                    guard case let .success(isAccepted) = result else {
                        return fail()
                    }
                    expect(isAccepted).to(equal(false))
                }
            }

            it("Should fetch accepted status") {
                let user = TestingUser(state: .loggedIn)
                var stubSignup = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                stubSignup.returnData(json: JSONObject.fromFile("agreements-valid-accepted"))
                stubSignup.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stubSignup)

                user.agreements.status { result in
                    guard case let .success(isAccepted) = result else {
                        return fail()
                    }
                    expect(isAccepted).to(equal(true))
                }
            }

            it("Should refresh on invalid token") {
                let user = TestingUser(state: .loggedIn)

                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("valid-refresh"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                var wantedStub = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                wantedStub.returnData([
                    (data: Data.fromFile("empty"), statusCode: 401),
                    (data: Data.fromFile("agreements-valid-accepted"), statusCode: 200),
                ])
                StubbedNetworkingProxy.addStub(wantedStub)

                user.agreements.status { result in
                    expect(result).to(beSuccess())
                }
            }

            it("Should report an error on invalid user ID") {
                let user = TestingUser(state: .loggedIn)

                var stub = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                stub.returnData(json: JSONObject.fromFile("agreements-invalid-wrong-user"))
                stub.returnResponse(status: 403)
                StubbedNetworkingProxy.addStub(stub)

                user.agreements.status { result in
                    guard case let .failure(ClientError.networkingError(NetworkingError.unexpectedStatus(status, _))) = result else {
                        return fail()
                    }
                    expect(status).to(equal(403))
                }
            }
        }

        describe("Agreements acceptance") {
            it("Should fail if logged out") {
                let user = TestingUser(state: .loggedOut)
                user.agreements.accept { result in
                    expect(result).to(failWith(ClientError.invalidUser))
                }
            }

            it("Should be able to accept") {
                let user = TestingUser(state: .loggedIn)

                var stub = NetworkStub(path: .path(Router.acceptAgreements(userID: user.id!).path))
                stub.returnData(json: JSONObject.fromFile("agreements-accept-valid"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                user.agreements.accept { result in
                    expect(result).to(beSuccess())
                }
            }

            it("Should refresh on invalid token") {
                let user = TestingUser(state: .loggedIn)
                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("valid-refresh"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                var wantedStub = NetworkStub(path: .path(Router.acceptAgreements(userID: user.id!).path))
                wantedStub.returnData([
                    (data: Data.fromFile("token-invalid"), statusCode: 401),
                    (data: Data.fromFile("agreements-accept-valid"), statusCode: 200),
                ])
                StubbedNetworkingProxy.addStub(wantedStub)

                user.agreements.accept { result in
                    expect(result).to(beSuccess())
                }
            }

            it("Should report an error on invalid user ID") {
                let user = TestingUser(state: .loggedIn)
                var stub = NetworkStub(path: .path(Router.acceptAgreements(userID: user.id!).path))
                stub.returnData(json: JSONObject.fromFile("agreements-invalid-wrong-user"))
                stub.returnResponse(status: 403)
                StubbedNetworkingProxy.addStub(stub)

                user.agreements.accept { result in
                    guard case let .failure(ClientError.networkingError(NetworkingError.unexpectedStatus(status, _))) = result else {
                        return fail()
                    }
                    expect(status).to(equal(403))
                }
            }
        }
    }
}
