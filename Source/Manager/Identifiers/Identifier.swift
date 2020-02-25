//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
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
            if let components = try? phoneNumber.components() {
                return "\(PhoneNumber.self):\(components.countryCode):\(components.number)"
            } else {
                return "\(PhoneNumber.self):\(phoneNumber.normalizedPhoneNumber)"
            }
        }
    }

    private static let mappingsKey = "identifier.mappings"

    init?(serializedString: String) {
        let components = serializedString.components(separatedBy: ":")
        switch components.first {
        case .some("\(EmailAddress.self)") where components.count == 2:
            if let email = EmailAddress(components[1]) {
                self = Identifier(email)
                return
            }
        case .some("\(PhoneNumber.self)") where components.count <= 3:
            switch components.count {
            case 2 where !components[1].isEmpty:
                if let phone = PhoneNumber(fullNumber: components.first) {
                    self = Identifier(phone)
                    return
                }
            case 3 where !components[1].isEmpty && !components[2].isEmpty:
                let countryCode = components[1]
                let number = components[2]
                if let phone = PhoneNumber(countryCode: countryCode, number: number) {
                    self = Identifier(phone)
                    return
                }
            default:
                return nil
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
    public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
        switch lhs {
        case let .email(a):
            if case let .email(b) = rhs {
                return a == b
            }
            return false
        case let .phone(a):
            if case let .phone(b) = rhs {
                return a == b
            }
            return false
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
