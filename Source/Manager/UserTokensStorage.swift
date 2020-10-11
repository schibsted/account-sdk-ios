//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

private let kSPiDAccessToken = "AccessToken"

struct UserTokensStorage {
    func loadTokens() throws -> TokenData {
        let tokens: TokenData
        if let existingTokens = UserTokensKeychain().data().first {
            tokens = existingTokens
        } else {
            #if SWIFT_PACKAGE
            throw ClientError.invalidUser
            #else
            if let oldTokens = SPiDKeychainWrapper.accessTokenFromKeychain(forIdentifier: kSPiDAccessToken), let accessToken = oldTokens.accessToken {
                tokens = TokenData(accessToken: accessToken, refreshToken: oldTokens.refreshToken, idToken: nil, userID: oldTokens.userID)
                do {
                    // Store in new format
                    try store(tokens)
                    SPiDKeychainWrapper.removeAccessTokenFromKeychain(forIdentifier: kSPiDAccessToken)
                } catch {
                    log(level: .error, from: self, "failed to migrate \(tokens)", force: true)
                }
            } else {
                throw ClientError.invalidUser
            }
            #endif
        }

        log(level: .debug, from: self, "loaded \(tokens)")
        return tokens
    }

    func store(_ tokens: TokenData) throws {
        let keychain = UserTokensKeychain()
        keychain.addTokens(tokens)

        do {
            try keychain.saveInKeychain()
            log(level: .debug, from: self, "stored \(tokens)")
        } catch where (error as NSError).code == (-34018) {
            // Seems to be a private inaccessible constant :( https://osstatus.com/search/results?platform=all&framework=all&search=-34018
            //
            // Also, this seems to happen only on the simulator.
            let message = "Keychain error: make sure you have an entitlements file with shared keychain access"
            fatalError(message)
        } catch {
            log(level: .error, from: self, "error saving keychain for user: \(error)", force: true)
        }
    }

    func clear(_ tokens: TokenData) throws {
        let keychain = UserTokensKeychain()
        keychain.removeTokens(forAccessToken: tokens.accessToken)

        do {
            try keychain.saveInKeychain()
            #if !SWIFT_PACKAGE
            if SPiDKeychainWrapper.accessTokenFromKeychain(forIdentifier: kSPiDAccessToken) != nil {
                SPiDKeychainWrapper.removeAccessTokenFromKeychain(forIdentifier: kSPiDAccessToken)
            }
            #endif
            log(level: .debug, from: self, "cleared \(tokens)")
        } catch {
            log(level: .error, from: self, "error removing keychain for user: \(error)", force: true)
        }
    }

    func clearAll() throws {
        let keychain = UserTokensKeychain()
        keychain.removeAllTokens()

        do {
            try keychain.saveInKeychain()
            #if !SWIFT_PACKAGE
            if SPiDKeychainWrapper.accessTokenFromKeychain(forIdentifier: kSPiDAccessToken) != nil {
                SPiDKeychainWrapper.removeAccessTokenFromKeychain(forIdentifier: kSPiDAccessToken)
            }
            #endif
            log(level: .debug, from: self, "cleared ALL tokens")
        } catch {
            log(level: .error, from: self, "error removing keychain for user: \(error)", force: true)
        }
    }
}
