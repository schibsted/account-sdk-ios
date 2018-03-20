//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Mockingjay
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
                stubSignup.returnFile(file: "agreements-valid-unaccepted", type: "json", in: Bundle(for: TestingUser.self))
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
                stubSignup.returnFile(file: "agreements-valid-accepted", type: "json", in: Bundle(for: TestingUser.self))
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
                self.stub(uri("/oauth/token"), try! Builders.load(file: "valid-refresh", status: 200))
                self.stub(uri("/api/2/user/\(user.id!)/agreements"), Builders.sequentialBuilder([
                    try! Builders.load(file: "token-invalid", status: 401),
                    try! Builders.load(file: "agreements-valid-accepted", status: 200),
                ]))

                user.agreements.status { result in
                    expect(result).to(beSuccess())
                }
            }

            it("Should report an error on invalid user ID") {
                let user = TestingUser(state: .loggedIn)

                var stub = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                stub.returnFile(file: "agreements-invalid-wrong-user", type: "json", in: Bundle(for: TestingUser.self))
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
                stub.returnFile(file: "agreements-accept-valid", type: "json", in: Bundle(for: TestingUser.self))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                user.agreements.accept { result in
                    expect(result).to(beSuccess())
                }
            }

            it("Should refresh on invalid token") {
                let user = TestingUser(state: .loggedIn)
                self.stub(uri("/oauth/token"), try! Builders.load(file: "valid-refresh", status: 200))
                self.stub(uri("/api/2/user/\(user.id!)/agreements/accept"), Builders.sequentialBuilder([
                    try! Builders.load(file: "token-invalid", status: 401),
                    try! Builders.load(file: "agreements-accept-valid", status: 200),
                ]))

                user.agreements.accept { result in
                    expect(result).to(beSuccess())
                }
            }

            it("Should report an error on invalid user ID") {
                let user = TestingUser(state: .loggedIn)
                var stub = NetworkStub(path: .path(Router.acceptAgreements(userID: user.id!).path))
                stub.returnFile(file: "agreements-invalid-wrong-user", type: "json", in: Bundle(for: TestingUser.self))
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
