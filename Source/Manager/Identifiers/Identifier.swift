//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

private func keyValueTuples(_ array: [JSONObject]) -> [(key: String, value: String)] {
    return array
        .compactOrFlatMap { (json) -> (key: String, value: String)? in
            guard let key = try? json.string(for: "key") else { return nil }
            guard let value = try? json.string(for: "value") else { return nil }
            return (key, value)
        }
}

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
            return "\(EmailAddress.self):\(email.normalizedString)"
        case let .phone(phoneNumber):
            let (normalizedCountryCode, normalizedNumber) = phoneNumber.normalizedValue
            return "\(PhoneNumber.self):\(normalizedCountryCode):\(normalizedNumber)"
        }
    }

    private static let mappingsKey = "identifier.mappings"

    init?(serializedString: String) {
        let components = serializedString.components(separatedBy: ":")
        let value = components.dropFirst().joined(separator: ":")
        guard let typeString = components.first else {
            return nil
        }
        switch typeString {
        case "\(EmailAddress.self)":
            if let email = EmailAddress(value) {
                self = Identifier(email)
                return
            }
        case "\(PhoneNumber.self)":
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
        let maxCount = 12

        /* Stored in JSON format:
         [
           { "key": "key0", value: value0 },
           { "key": "key1", value: value1 },
           ...
           { "key": "keyN", value: valueN },
         ]

         It is stored in an array so it can be used as a FIFO
        */

        // First check if we already have a key mapping for this identifier
        var array = (Settings.value(forKey: Identifier.mappingsKey) as? [JSONObject]) ?? []
        let serializedString = self.serializedString

        let maybeKey = keyValueTuples(array)
            .filter { $0.value == serializedString }
            .first?
            .key

        if let key = maybeKey {
            return key
        }

        // Create a key mapping if we didn't find one
        let uuid = UUID().uuidString
        let key = String(uuid[..<uuid.index(uuid.startIndex, offsetBy: 8)])

        while array.count >= maxCount {
            array.remove(at: 0)
        }

        array.append([
            "key": key,
            "value": serializedString,
        ])

        Settings.setValue(array, forKey: Identifier.mappingsKey)
        return key
    }

    init?(localID: String) {
        guard let array = Settings.value(forKey: Identifier.mappingsKey) as? [JSONObject] else {
            return nil
        }

        let maybeValue = keyValueTuples(array)
            .filter { $0.key == localID }
            .first?
            .value

        guard let value = maybeValue else {
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
