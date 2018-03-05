//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

func storeWithPreviousKeychainLayout(tokens: TokenData) throws {

    let dataToStore: [String: Any] = [
        UserTokensKeychain.Keys.accessToken: tokens.accessToken,
        UserTokensKeychain.Keys.refreshToken: tokens.refreshToken,
        UserTokensKeychain.Keys.idToken: tokens.idToken?.string ?? nil,
        UserTokensKeychain.Keys.legacyUserID: tokens.userID,
    ].compactedValues()

    let archivedData = NSKeyedArchiver.archivedData(withRootObject: dataToStore)

    var attributes = [String: Any]()

    attributes[String(kSecClass)] = kSecClassGenericPassword
    attributes[String(kSecAttrAccessible)] = String(kSecAttrAccessibleWhenUnlocked)
    attributes[String(kSecAttrService)] = "swift.keychain.service"
    attributes[String(kSecAttrAccount)] = "SchibstedAccount"
    attributes[String(kSecValueData)] = archivedData

    var statusCode = SecItemAdd(attributes as CFDictionary, nil)

    if statusCode == errSecDuplicateItem {
        SecItemDelete(attributes as CFDictionary)
        statusCode = SecItemAdd(attributes as CFDictionary, nil)
    }

    if statusCode != errSecSuccess {
        throw NSError(domain: "UserTokensKeychainTests.storeWithPreviousKeychainLayout", code: Int(statusCode), userInfo: nil)
    }
}

func loadWithPreviousKeychainLayout() throws -> TokenData {
    var attributes = [String: Any]()

    attributes[String(kSecClass)] = kSecClassGenericPassword
    attributes[String(kSecAttrAccessible)] = String(kSecAttrAccessibleWhenUnlocked)
    attributes[String(kSecAttrService)] = "swift.keychain.service"
    attributes[String(kSecAttrAccount)] = "SchibstedAccount"
    attributes[String(kSecReturnData)] = kCFBooleanTrue
    attributes[String(kSecReturnAttributes)] = kCFBooleanTrue

    var maybeResult: AnyObject?
    let statusCode = SecItemCopyMatching(attributes as CFDictionary, &maybeResult)

    if statusCode != errSecSuccess {
        throw NSError(domain: "UserTokensKeychainTests.loadWithPreviousKeychainLayout", code: Int(statusCode), userInfo: nil)
    }

    guard let result = maybeResult as? [String: Any] else {
        throw NSError(
            domain: "UserTokensKeychainTests.loadWithPreviousKeychainLayout",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "no returned attributes"]
        )
    }

    guard let archivedData = result[String(kSecValueData)] as? Data else {
        throw NSError(
            domain: "UserTokensKeychainTests.loadWithPreviousKeychainLayout",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "no value data"]
        )
    }

    guard let data = NSKeyedUnarchiver.unarchiveObject(with: archivedData) as? [String: Any] else {
        throw NSError(
            domain: "UserTokensKeychainTests.loadWithPreviousKeychainLayout",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "couldnt unarchive data"]
        )
    }

    let accessToken = try data.string(for: UserTokensKeychain.Keys.accessToken)
    let refreshToken = try? data.string(for: UserTokensKeychain.Keys.refreshToken)
    let userID = try? data.string(for: UserTokensKeychain.Keys.legacyUserID)

    var idToken: IDToken?
    if let string = try? data.string(for: UserTokensKeychain.Keys.idToken) {
        idToken = try? IDToken(string: string)
    }

    return TokenData(accessToken: accessToken, refreshToken: refreshToken, idToken: idToken, userID: userID)
}

class UserTokensKeychainTests: QuickSpec {

    override func spec() {

        describe("Loading") {

            it("should have no tokens with nothing stored") {
                expect(UserTokensKeychain().data().count) == 0
            }

            it("should load previous keychain layout") {
                let storedTokens = TokenData(accessToken: "one", refreshToken: "two", idToken: "three", userID: "four")
                try! storeWithPreviousKeychainLayout(tokens: storedTokens)

                let loadedTokens = UserTokensKeychain().data().first
                expect(loadedTokens) == storedTokens
            }

            it("should load all stored users") {
                var numbersBucket = Set(0..<10)

                do {
                    let keychain = UserTokensKeychain()
                    for i in numbersBucket {
                        let str = "\(i)"
                        let tokens = TokenData(accessToken: str, refreshToken: str, idToken: IDToken(stringLiteral: str), userID: str)
                        keychain.addTokens(tokens)
                    }
                    try! keychain.saveInKeychain()
                }

                let keychain = UserTokensKeychain()
                let data = keychain.data()
                expect(data.count) == numbersBucket.count
                for tokens in data {
                    numbersBucket.remove(Int(tokens.accessToken)!)
                }
                expect(numbersBucket.count) == 0
            }
        }

        describe("Saving") {

            it("should remove from old format and store in new format") {
                let storedTokens = TokenData(accessToken: "one", refreshToken: "two", idToken: "three", userID: "four")
                try! storeWithPreviousKeychainLayout(tokens: storedTokens)

                try! UserTokensKeychain().saveInKeychain()

                expect { try loadWithPreviousKeychainLayout() }.to(throwError(JSONError.noKey("")))
            }
        }
    }
}
