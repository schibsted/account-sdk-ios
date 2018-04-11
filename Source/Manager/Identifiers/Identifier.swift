//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Represents an identier that is used to initiate login processes
 */
public enum Identifier: IdentifierProtocol {
    /// User identifier representing a phone number
    case phone(PhoneNumber)

    /// User identifier representing an email address
    case email(EmailAddress)

    ///
    public init(_ email: EmailAddress) {
        self = .email(email)
    }

    ///
    public init(_ phone: PhoneNumber) {
        self = .phone(phone)
    }

    init?(_ identifier: IdentifierProtocol) {
        if let identifier = identifier as? EmailAddress {
            self.init(identifier)
        } else if let identifier = identifier as? PhoneNumber {
            self.init(identifier)
        }
        return nil
    }

    /// The string that is provided during initialization
    public var originalString: String {
        switch self {
        case let .email(email): return email.originalString
        case let .phone(phone): return phone.originalString
        }
    }

    /// The normalized form used internally (may or may not be different)
    public var normalizedString: String {
        switch self {
        case let .email(email): return email.normalizedString
        case let .phone(phone): return phone.normalizedString
        }
    }

    var serializedString: String {
        switch self {
        case let .email(email):
            return "\(self.typeString):\(email.normalizedString)"
        case let .phone(phoneNumber):
            let (normalizedCountryCode, normalizedNumber) = phoneNumber.normalizedValue
            return "\(self.typeString):\(normalizedCountryCode):\(normalizedNumber)"
        }
    }

    private static let mappingsKey = "identifier.mappings"
    private static let emailTypeString = "email"
    private static let phoneTypeString = "phone"
    private var typeString: String {
        switch self {
        case .email:
            return Identifier.emailTypeString
        case .phone:
            return Identifier.phoneTypeString
        }
    }

    init?(serializedString: String) {
        let components = serializedString.components(separatedBy: ":")
        let value = components.dropFirst().joined(separator: ":")
        switch components.first {
        case .some(Identifier.emailTypeString):
            if let email = EmailAddress(value) {
                self = Identifier(email)
                return
            }
        case .some(Identifier.phoneTypeString):
            let phoneComponents = value.split(separator: ":").map { String($0) }
            guard phoneComponents.count == 2 && !phoneComponents[0].isEmpty && !phoneComponents[1].isEmpty else {
                return nil
            }
            let countryCode = phoneComponents[0]
            let number = phoneComponents[1]

            if let phone = PhoneNumber(countryCode: countryCode, number: number) {
                self = Identifier(phone)
                return
            }
        default:
            return nil
        }
        return nil
    }

    /**
     Creates a locally static (application wide) id for an identifier so that you can send that
     around the wire instead of sendin the actual ID.
     */
    func localID() -> String {
        /* Stored in JSON format:
         {
           "key0": { value: value0 }
           "key1": { value: value1 }
           ...
           "keyN": { value: valueN }
         }
        */

        // First check if we already have a key mapping for this identifier
        var json = (Settings.value(forKey: Identifier.mappingsKey) as? JSONObject) ?? [:]
        let serializedString = self.serializedString

        let maybeKey = json
            .map { (key: $0.key, data: $0.value as? JSONObject) }
            .filter { (try? $0.data?.string(for: "value")) == serializedString }
            .first?
            .key

        if let key = maybeKey {
            return key
        }

        // Create a key mapping if we didn't find one
        let uuid = UUID().uuidString
        let key = String(uuid[..<uuid.index(uuid.startIndex, offsetBy: 8)])

        json[key] = [
            "value": serializedString,
        ]

        Settings.setValue(json, forKey: Identifier.mappingsKey)
        return key
    }

    init?(localID: String) {
        guard let json = Settings.value(forKey: Identifier.mappingsKey) as? JSONObject else {
            return nil
        }

        guard let data = try? json.jsonObject(for: localID) else {
            return nil
        }

        guard let value = try? data.string(for: "value") else {
            return nil
        }

        self.init(serializedString: value)
    }
}

extension Identifier: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .email(email): return email.normalizedString
        case let .phone(phone): return phone.normalizedString
        }
    }
}

extension Identifier: Equatable {
    /// Returns true if both normalized forms are equal
    public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
        switch (lhs, rhs) {
        case let (.email(a), .email(b)) where a.normalizedString == b.normalizedString: return true
        case let (.phone(a), .phone(b)) where a.normalizedString == b.normalizedString: return true
        default: return false
        }
    }
}

extension Identifier {
    var connection: Connection {
        switch self {
        case .phone: return .sms
        case .email: return .email
        }
    }
}
