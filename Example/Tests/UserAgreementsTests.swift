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
                self.stub(uri("/api/2/user/\(user.id!)/agreements"), try! Builders.load(file: "agreements-valid-unaccepted", status: 200))

                user.agreements.status { result in
                    guard case let .success(isAccepted) = result else {
                        return fail()
                    }
                    expect(isAccepted).to(equal(false))
                }
            }

            it("Should fetch accepted status") {
                let user = TestingUser(state: .loggedIn)
                self.stub(uri("/api/2/user/\(user.id!)/agreements"), try! Builders.load(file: "agreements-valid-accepted", status: 200))

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
                self.stub(uri("/api/2/user/\(user.id!)/agreements"), try! Builders.load(file: "agreements-invalid-wrong-user", status: 403))

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
                self.stub(uri("/api/2/user/\(user.id!)/agreements/accept"), try! Builders.load(file: "agreements-accept-valid", status: 200))

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
                self.stub(uri("/api/2/user/\(user.id!)/agreements/accept"), try! Builders.load(file: "agreements-invalid-wrong-user", status: 403))

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
