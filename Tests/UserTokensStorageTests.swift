//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

private let kAccessToken = "AccessToken"

class UserTokensStorageTests: QuickSpec {

    let testUserID = "testUserID"
    let testAccessToken = "testAccessToken"
    let testRefreshToken = "testRefreshToken"

    override func spec() {

        #if !SWIFT_PACKAGE
        beforeEach {
            let token = SPiDAccessToken(userID: self.testUserID, accessToken: self.testAccessToken, expiresAt: Date(), refreshToken: self.testRefreshToken)
            SPiDKeychainWrapper.storeInKeychainAccessToken(withValue: token, forIdentifier: kAccessToken)
        }

        afterEach {
            SPiDKeychainWrapper.removeAccessTokenFromKeychain(forIdentifier: kAccessToken)
        }
        #endif

        describe("Loading") {

            it("Should load user from SPiD keychain") {
                let tokens = try! UserTokensStorage().loadTokens()
                expect(tokens.accessToken).to(equal(self.testAccessToken))
                expect(tokens.refreshToken).to(equal(self.testRefreshToken))
                expect(tokens.userID).to(equal(self.testUserID))
            }

            it("Should load user from keychain") {
                #if !SWIFT_PACKAGE
                SPiDKeychainWrapper.removeAccessTokenFromKeychain(forIdentifier: kAccessToken)
                #endif
                
                let newAccessToken = "newAccessToken"
                let newRefreshToken = "newRefreshToken"
                let newUserID = "newUserID"

                Utils.createDummyKeychain(accessToken: newAccessToken, refreshToken: newRefreshToken, userID: newUserID)

                let tokens = try! UserTokensStorage().loadTokens()
                expect(tokens.accessToken).to(equal(newAccessToken))
                expect(tokens.refreshToken).to(equal(newRefreshToken))
                expect(tokens.userID).to(equal(newUserID))
            }

            it("Should clear SPiD keychain and still be loadable") {
                do {
                    let tokens = try! UserTokensStorage().loadTokens()
                    expect(tokens).toNot(beNil())
                }
                #if !SWIFT_PACKAGE
                let accessToken = SPiDKeychainWrapper.accessTokenFromKeychain(forIdentifier: kAccessToken)?.accessToken
                expect(accessToken).to(beNil())
                #endif
                do {
                    let tokens = try! UserTokensStorage().loadTokens()
                    expect(tokens).toNot(beNil())
                }
            }
        }

        describe("Storing") {

            it("Should be loadable by keychain") {
                let user = User(state: .loggedIn)
                let userStorage = UserTokensStorage()
                try? userStorage.store(user.tokens!)

                let tokens = try! UserTokensStorage().loadTokens()
                expect(tokens).to(equal(user.tokens))
            }
        }

        describe("Clearing") {

            it("Should clear both SPiD and normal keychain") {
                Utils.createDummyKeychain(accessToken: self.testAccessToken, refreshToken: self.testRefreshToken, userID: self.testUserID)
                let userStorage = UserTokensStorage()
                let tokens = try! userStorage.loadTokens()
                expect(tokens).toNot(beNil())
                try! userStorage.clear(tokens)
                let newTokens = try? userStorage.loadTokens()
                expect(newTokens).to(beNil())
            }
        }
    }
}
