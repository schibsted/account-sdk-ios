//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

final class SPiDKeychainWrapper {
    public class func accessTokenFromKeychain(forIdentifier identifier: String) -> SPiDAccessToken! {
        var query = setupSearchQuery(identifier: identifier)
        query[(kSecMatchLimitOne as String)] = true
        query[(kSecReturnData as String)] = true

        var cfData: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &cfData)
        if status == noErr, let data = cfData as? Data {
            if let accessToken = NSKeyedUnarchiver.unarchiveObject(with: data) as? SPiDAccessToken {
                return accessToken
            }
        }

        return nil
    }

    @discardableResult
    public class func storeInKeychainAccessToken(withValue accessToken: SPiDAccessToken, forIdentifier identifier: String) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: accessToken)
        var query = setupSearchQuery(identifier: identifier)
        query[(kSecValueData as String)] = data

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            return true
        } else if status == errSecDuplicateItem {
            return updateAccessTokenInKeychain(value: accessToken, forIdentifier: identifier)
        }

        return false
    }

    @discardableResult
    public class func updateAccessTokenInKeychain(value accessToken: SPiDAccessToken, forIdentifier identifier: String) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: accessToken)
        let searchQuery = setupSearchQuery(identifier: identifier)
        let updateQuery: [String: Any] = [(kSecValueData as String): data]

        let status = SecItemUpdate(searchQuery as CFDictionary, updateQuery as CFDictionary)
        return status == errSecSuccess
    }

    public class func removeAccessTokenFromKeychain(forIdentifier identifier: String) {
        let query = setupSearchQuery(identifier: identifier)
        let status = SecItemDelete(query as CFDictionary)
        if status != noErr {
            log("Error deleting item to keychain - \(status)")
        }
    }

    private class var serviceNameForSPiD: String {
        let appName = Bundle.main.bundleIdentifier!
        return "\(appName)-SPiD"
    }

    private class func setupSearchQuery(identifier: String) -> [String: Any] {
        return [(kSecClass as String): kSecClassGenericPassword,
                (kSecAttrGeneric as String): identifier,
                (kSecAttrAccount as String): identifier,
                (kSecAttrService as String): serviceNameForSPiD]
    }
}
