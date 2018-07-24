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

    let numberOfDigitsInNormalizedCountryCode: Int?

    /// The string that is provided during initialization
    public var originalString: String {
        return self.phoneNumber
    }

    /// The normalized form used internally (may or may not be different)
    public var normalizedString: String {
        return self.normalizedPhoneNumber
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
        let startIndexOfNumberPart = self.normalizedPhoneNumber.index(
            self.normalizedPhoneNumber.startIndex,
            offsetBy: numberOfDigits
        )
        return Components(
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

    /**
     Initialize PhoneNumber identifier

     Assumes the values passed in is a full phone number including the internal dialing code. The number is normalized by removing '00' in the
     front (if present) and adding '+' as the first char.

     - parameter fullNumber: a phone number including full country code
     - returns: PhoneNumber or nil if parsing fails
     */
    public init?(fullNumber: String?) {
        guard let fullNumber = fullNumber else { return nil }
        guard let normalizedPhoneNumber = PhoneNumber.normalize(fullNumber, isCountryCode: true) else { return nil }
        self.phoneNumber = fullNumber
        self.normalizedPhoneNumber = normalizedPhoneNumber
        self.numberOfDigitsInNormalizedCountryCode = nil
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
