//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class IdentifierTests: QuickSpec {

    let testCountryCode = "47"
    lazy var testCountryCodeWithPlus = "+" + testCountryCode
    lazy var testCountryCodeWith00 = "00" + testCountryCode
    let testNumberRaw = "12345678"
    let testNumerWithSpaces = "1 2 3 4 5 6 7 8"
    lazy var testNormalizedNumber = testCountryCodeWithPlus + testNumberRaw
    lazy var testPhoneNumber = PhoneNumber(countryCode: testCountryCodeWithPlus, number: testNumberRaw)!
    let testEmailRaw = "hello@bubble.com"
    lazy var testEmailAddress = EmailAddress(testEmailRaw)!

    override func spec() {

        describe("Identifier") {

            it("Should have original email") {
                let identifier = Identifier(self.testEmailAddress)
                expect(identifier.originalString) == self.testEmailRaw
            }

            it("Should have original phone number") {
                let identifier = Identifier(self.testPhoneNumber)
                expect(identifier.originalString) == self.testCountryCodeWithPlus + self.testNumberRaw
            }
        }

        describe("serelization") {

            it("should serialize phone numbers and unserialize to same number") {
                let serialized = Identifier(self.testPhoneNumber).serializedString
                let identifier = Identifier(serializedString: serialized)!
                let expected = Identifier(self.testPhoneNumber)
                expect(identifier) == expected
            }

            it("should serialize emails and unserialize to same number") {
                let serialized = Identifier(self.testEmailAddress).serializedString
                let identifier = Identifier(serializedString: serialized)!
                let expected = Identifier(self.testEmailAddress)
                expect(identifier) == expected
            }
        }

        describe("local ID") {

            it("should return correct email identiier") {
                let expected = Identifier(self.testEmailAddress)
                let localID = expected.localID()
                let identifier = Identifier(localID: localID)!
                expect(identifier) == expected
            }

            it("should return correct phone number identiier") {
                let expected = Identifier(self.testPhoneNumber)
                let localID = expected.localID()
                let identifier = Identifier(localID: localID)!
                expect(identifier) == expected
            }

            it("should return same id with mutiple invocations on phone number") {
                let id1 = Identifier(self.testPhoneNumber).localID()
                let id2 = Identifier(self.testPhoneNumber).localID()
                expect(id1) == id2
            }

            it("should return same id with mutiple invocations on email") {
                let id1 = Identifier(self.testEmailAddress).localID()
                let id2 = Identifier(self.testEmailAddress).localID()
                expect(id1) == id2
            }

        }

        describe("Normalizing PhoneNumber") {

            it("Should automatically add a + to phone numbers that don't have one") {
                let phoneNumber = PhoneNumber(countryCode: self.testCountryCode, number: self.testNumberRaw)
                expect(phoneNumber?.normalizedString) == self.testNormalizedNumber
                expect(phoneNumber?.normalizedValue.countryCode) == self.testCountryCodeWithPlus
                expect(phoneNumber?.normalizedValue.number) == self.testNumberRaw
            }

            it("Should leave number with + intact") {
                let phoneNumber = PhoneNumber(countryCode: self.testCountryCodeWithPlus, number: self.testNumberRaw)
                expect(phoneNumber?.normalizedString) == self.testNormalizedNumber
                expect(phoneNumber?.normalizedValue.countryCode) == self.testCountryCodeWithPlus
                expect(phoneNumber?.normalizedValue.number) == self.testNumberRaw
            }

            it("Should strip 00 and add a +") {
                let phoneNumber = PhoneNumber(countryCode: self.testCountryCodeWith00, number: self.testNumberRaw)
                expect(phoneNumber?.normalizedString) == self.testNormalizedNumber
                expect(phoneNumber?.normalizedValue.countryCode) == self.testCountryCodeWithPlus
                expect(phoneNumber?.normalizedValue.number) == self.testNumberRaw
            }

            it("Should be nil if number has non valid phone characters in it") {
                expect(PhoneNumber(countryCode: "+++", number: "123")).to(beNil())
                expect(PhoneNumber(countryCode: "+7f", number: "123")).to(beNil())
                expect(PhoneNumber(countryCode: "8375hh", number: "123")).to(beNil())
                expect(PhoneNumber(countryCode: "+47", number: "123f")).to(beNil())
                expect(PhoneNumber(countryCode: "+47", number: "")).to(beNil())
                expect(PhoneNumber(countryCode: "", number: "123")).to(beNil())
            }

            it("Should remove spaces") {
                expect(PhoneNumber(countryCode: "+47", number: self.testNumerWithSpaces)?.normalizedString) == self.testNormalizedNumber
            }
        }
    }
}
