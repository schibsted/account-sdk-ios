//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Mockingjay
import Nimble
import Quick
@testable import SchibstedAccount

class UserAuthTests: QuickSpec {

    override func spec() {

        describe("Token exchange") {
            it("Should fail if logged out") {
                self.stub(uri("/api/2/oauth/exchange"), try! Builders.load(file: "token-exchange-valid", status: 200))

                let user = TestingUser(state: .loggedOut)
                user.auth.oneTimeCode(clientID: ClientConfiguration.testing.clientID) { result in
                    expect(result).to(failWith(ClientError.invalidUser))
                }
            }

            it("Should return a code") {
                self.stub(uri("/api/2/oauth/exchange"), try! Builders.load(file: "token-exchange-valid", status: 200))

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
                self.stub(uri("/oauth/token"), try! Builders.load(file: "valid-refresh", status: 200))
                self.stub(uri("/api/2/oauth/exchange"), Builders.sequentialBuilder([
                    try! Builders.load(file: "token-invalid", status: 401),
                    try! Builders.load(file: "token-exchange-valid", status: 200),
                ]))

                user.auth.oneTimeCode(clientID: ClientConfiguration.testing.clientID) { result in
                    expect(result).to(beSuccess())
                }
            }
        }
    }
}
