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
