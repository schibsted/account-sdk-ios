//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/// Represents a phone number string
public struct PhoneNumber: IdentifierProtocol {
    let phoneNumber: String
    let normalizedPhoneNumber: String

    let numberOfDigitsInNormalizedCountryCode: Int?

    /// The string that is provided during initialization
    public var originalString: String {
        return phoneNumber
    }

    /// The normalized form used internally (may or may not be different)
    public var normalizedString: String {
        return normalizedPhoneNumber
    }

    /// Represents the components of a full phone number, i.e. dialing code and number
    public struct Components {
        let countryCode: String
        let number: String
    }

    /**
     Create a PhoneNumber.Components object out of this PhoneNumber.

     This will only work if you have used the initializer that allows seperation of code and parts
     */
    public func components() throws -> Components {
        guard let numberOfDigits = numberOfDigitsInNormalizedCountryCode else {
            throw ClientError.invalidPhoneNumber
        }
        let startIndexOfNumberPart = normalizedPhoneNumber.index(
            normalizedPhoneNumber.startIndex,
            offsetBy: numberOfDigits
        )
        return Components(
            countryCode: String(normalizedPhoneNumber[..<startIndexOfNumberPart]),
            number: String(normalizedPhoneNumber[startIndexOfNumberPart...])
        )
    }

    /**
     Initialize PhoneNumber identifier

     The input strings are only allowed to have digits or spaces, with the exception of '+' that may be present in the country code. There must be at least one
     digit in each string. The country code is normalized by removing '00' in the front (if present) and adding '+' as the first char.

     - parameter countryCode: a phone number's country code as a string to parse
     - parameter identifier: a phone number as a string to parse
     - returns: PhoneNumber or nil if parsing fails
     */
    public init?(countryCode: String, number: String) {
        guard let normalizedCountryCode = PhoneNumber.normalizeCountryCode(countryCode),
              let normalizedNumber = PhoneNumber.normalizeNumberComponent(number)
        else {
            return nil
        }
        phoneNumber = countryCode + number
        normalizedPhoneNumber = normalizedCountryCode + normalizedNumber
        numberOfDigitsInNormalizedCountryCode = normalizedCountryCode.count
    }

    /**
     Initialize PhoneNumber identifier

     Assumes the values passed in is a full phone number including the internal dialing code. The number is normalized by removing '00' in the
     front (if present) and adding '+' as the first char.

     - parameter fullNumber: a phone number including full country code
     - returns: PhoneNumber or nil if parsing fails
     */
    public init?(fullNumber: String?) {
        guard let fullNumber = fullNumber else { return nil }
        guard let normalizedPhoneNumber = PhoneNumber.normalizeFullNumber(fullNumber) else { return nil }
        phoneNumber = fullNumber
        self.normalizedPhoneNumber = normalizedPhoneNumber
        numberOfDigitsInNormalizedCountryCode = nil
    }

    private static func normalizeFullNumber(_ value: String) -> String? {
        var string = value.filter { $0 != " " }

        if string.hasPrefix("+") {
            string.remove(at: string.startIndex)
        } else if string.hasPrefix("00") {
            string.removeFirst(2)
        } else {
            return nil
        }

        guard string.count > 0, string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
            return nil
        }
        return "+" + string
    }

    private static func normalizeCountryCode(_ value: String) -> String? {
        if !value.hasPrefix("+"), !value.hasPrefix("00") {
            return normalizeFullNumber("+" + value)
        } else {
            return normalizeFullNumber(value)
        }
    }

    private static func normalizeNumberComponent(_ value: String) -> String? {
        let digits = value.filter { $0 != " " }
        guard digits.count > 0, digits.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
            return nil
        }
        return digits
    }
}

extension PhoneNumber: Equatable {
    public static func == (lhs: PhoneNumber, rhs: PhoneNumber) -> Bool {
        return lhs.normalizedString == rhs.normalizedString
    }
}
