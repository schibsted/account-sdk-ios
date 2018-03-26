//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

private extension CharacterSet {
    static func phoneNumberCharacterSet() -> CharacterSet {
        return CharacterSet(charactersIn: "0123456789 +")
    }
}

/// Represents a phone number string
public struct PhoneNumber: IdentifierProtocol {
    let phoneNumber: String
    let normalizedPhoneNumber: String

    let numberOfDigitsInNormalizedCountryCode: Int

    /// The string that is provided during initialization
    public var originalString: String {
        return self.phoneNumber
    }

    /// The normalized form used internally (may or may not be different)
    public var normalizedString: String {
        return self.normalizedPhoneNumber
    }

    var normalizedValue: (countryCode: String, number: String) {
        let startIndexOfNumberPart = self.normalizedPhoneNumber.index(
            self.normalizedPhoneNumber.startIndex,
            offsetBy: self.numberOfDigitsInNormalizedCountryCode
        )
        return (
            countryCode: String(self.normalizedPhoneNumber[..<startIndexOfNumberPart]),
            number: String(self.normalizedPhoneNumber[startIndexOfNumberPart...])
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
        guard let normalizedCountryCode = PhoneNumber.normalize(countryCode, isCountryCode: true),
            let normalizedNumber = PhoneNumber.normalize(number, isCountryCode: false)
        else {
            return nil
        }
        self.phoneNumber = countryCode + number
        self.normalizedPhoneNumber = normalizedCountryCode + normalizedNumber
        self.numberOfDigitsInNormalizedCountryCode = normalizedCountryCode.count
    }

    static func normalize(_ identifier: String, isCountryCode: Bool) -> String? {
        guard identifier.rangeOfCharacter(from: CharacterSet.phoneNumberCharacterSet().inverted) == nil else {
            return nil
        }

        let decimalDigitCharacters = identifier.filter {
            String($0).rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
        }

        guard decimalDigitCharacters.count > 0 else {
            return nil
        }

        let normalizedPhoneNumber = String(decimalDigitCharacters)

        guard isCountryCode else {
            return normalizedPhoneNumber
        }

        guard normalizedPhoneNumber.hasPrefix("00") else {
            return "+" + normalizedPhoneNumber
        }

        return "+" + normalizedPhoneNumber[normalizedPhoneNumber.index(normalizedPhoneNumber.startIndex, offsetBy: 2)...]
    }
}
