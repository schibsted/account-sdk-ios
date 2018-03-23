//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/*
 Copyright (c) 2016 Yanko Dimitrov http://www.yankodimitrov.com/

 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

// MARK: - KeychainServiceType

protocol KeychainServiceType {

    func insertItemWithAttributes(_ attributes: [String: Any]) throws
    func removeItemWithAttributes(_ attributes: [String: Any]) throws
    func fetchItemWithAttributes(_ attributes: [String: Any]) throws -> [String: Any]?
}

// MARK: - KeychainItemType

protocol KeychainItemType {

    var accessMode: String { get }
    var accessGroup: String? { get }
    var attributes: [String: Any] { get }
    var fetchedData: [String: Any] { get set }
    var dataToStore: [String: Any] { get }
}

extension KeychainItemType {

    var accessMode: String {

        return String(kSecAttrAccessibleWhenUnlocked)
    }

    var accessGroup: String? {

        return nil
    }
}

extension KeychainItemType {

    internal var attributesToSave: [String: Any] {

        var itemAttributes = attributes
        let archivedData = NSKeyedArchiver.archivedData(withRootObject: dataToStore)

        itemAttributes[String(kSecValueData)] = archivedData

        if let group = accessGroup {

            itemAttributes[String(kSecAttrAccessGroup)] = group
        }

        return itemAttributes
    }

    internal func dataFromAttributes(_ attributes: [String: Any]) -> [String: Any]? {

        guard let valueData = attributes[String(kSecValueData)] as? Data else { return nil }

        return NSKeyedUnarchiver.unarchiveObject(with: valueData) as? [String: Any] ?? nil
    }

    internal var attributesForFetch: [String: Any] {

        var itemAttributes = attributes

        itemAttributes[String(kSecReturnData)] = kCFBooleanTrue
        itemAttributes[String(kSecReturnAttributes)] = kCFBooleanTrue

        if let group = accessGroup {

            itemAttributes[String(kSecAttrAccessGroup)] = group
        }

        return itemAttributes
    }
}

// MARK: - KeychainGenericPasswordType

protocol KeychainGenericPasswordType: KeychainItemType {

    var serviceName: String { get }
    var accountName: String { get }
}

extension KeychainGenericPasswordType {

    var serviceName: String {

        return "swift.keychain.service"
    }

    var attributes: [String: Any] {

        var attributes = [String: Any]()

        attributes[String(kSecClass)] = kSecClassGenericPassword
        attributes[String(kSecAttrAccessible)] = accessMode
        attributes[String(kSecAttrService)] = serviceName
        attributes[String(kSecAttrAccount)] = accountName

        return attributes
    }
}

// MARK: - Keychain

struct Keychain: KeychainServiceType {

    internal func errorForStatusCode(_ statusCode: OSStatus) -> NSError {

        return NSError(domain: "swift.keychain.error", code: Int(statusCode), userInfo: nil)
    }

    // Inserts or updates a keychain item with attributes

    public func insertItemWithAttributes(_ attributes: [String: Any]) throws {

        var statusCode = SecItemAdd(attributes as CFDictionary, nil)

        if statusCode == errSecDuplicateItem {

            SecItemDelete(attributes as CFDictionary)
            statusCode = SecItemAdd(attributes as CFDictionary, nil)
        }

        if statusCode != errSecSuccess {

            throw self.errorForStatusCode(statusCode)
        }
    }

    public func removeItemWithAttributes(_ attributes: [String: Any]) throws {

        let statusCode = SecItemDelete(attributes as CFDictionary)

        if statusCode != errSecSuccess {

            throw self.errorForStatusCode(statusCode)
        }
    }

    public func fetchItemWithAttributes(_ attributes: [String: Any]) throws -> [String: Any]? {

        var result: AnyObject?

        let statusCode = SecItemCopyMatching(attributes as CFDictionary, &result)

        if statusCode != errSecSuccess {

            throw self.errorForStatusCode(statusCode)
        }

        if let result = result as? [String: Any] {

            return result
        }

        return nil
    }
}

// MARK: - KeychainItemType + Keychain

extension KeychainItemType {

    func saveInKeychain(_ keychain: KeychainServiceType = Keychain()) throws {

        try keychain.insertItemWithAttributes(self.attributesToSave)
    }

    func removeFromKeychain(_ keychain: KeychainServiceType = Keychain()) throws {

        try keychain.removeItemWithAttributes(attributes)
    }

    mutating func fetchFromKeychain(_ keychain: KeychainServiceType = Keychain()) throws -> Self {

        if let result = try keychain.fetchItemWithAttributes(attributesForFetch),
            let itemData = dataFromAttributes(result) {

            fetchedData = itemData
        }

        return self
    }
}
