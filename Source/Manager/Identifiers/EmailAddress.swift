//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/// Represents an email address as a string
public struct EmailAddress: IdentifierProtocol, Equatable {
    let emailAddress: String

    /// The string that is provided during initialization
    public var originalString: String {
        return emailAddress
    }

    /// The normalized form used internally (may or may not be different)
    public var normalizedString: String {
        return emailAddress
    }

    /**
     Initialize EmailAddress identifier

     Not full spec. Just uses a regext to ensure that there a character before and after
     the @ symbol followed by at least one period and another character

     - parameter identifier: an emaila ddress as a string to parse
     - returns: EmailAddress or nil if parsing fails
     */
    public init?(_ string: String) {
        guard let identifier = EmailAddress.normalize(string) else {
            return nil
        }
        emailAddress = identifier
    }

    static func normalize(_ identifier: String) -> String? {
        guard identifier.count > 0 else {
            return nil
        }

        let pattern = "^.+@.+\\..+$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            assertionFailure("Invalid NSRegularExpression pattern: \(pattern)")
            return nil
        }

        let range = NSRange(location: 0, length: identifier.count)
        guard regex.numberOfMatches(in: identifier, range: range) > 0 else {
            return nil
        }

        return identifier
    }
}
