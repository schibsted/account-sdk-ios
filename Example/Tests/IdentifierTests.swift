//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class IdentifierTests: QuickSpec {

    override func spec() {

        describe("Identifier") {

            it("Should have original email") {
                let emailAddress = "hello@bubble.com"
                let identifier = Identifier(EmailAddress(emailAddress)!)
                expect(identifier.originalString) == emailAddress
            }

            it("Should have original phone number") {
                let countryCode = "+47"
                let number = "01020304"
                let identifier = Identifier(PhoneNumber(countryCode: countryCode, number: number)!)
                expect(identifier.originalString) == countryCode + number
            }
        }

        describe("Normalizing PhoneNumber") {

            let testCountryCode = "47"
            let testCountryCodeWithPlus = "+" + testCountryCode
            let testCountryCodeWith00 = "00" + testCountryCode
            let testNumber = "12345678"
            let testNumerWithSpaces = "1 2 3 4 5 6 7 8"
            let expectedNumber = testCountryCodeWithPlus + testNumber

            it("Should automatically add a + to phone numbers that don't have one") {
                let phoneNumber = PhoneNumber(countryCode: testCountryCode, number: testNumber)
                expect(phoneNumber?.normalizedString) == expectedNumber
                expect(phoneNumber?.normalizedValue.countryCode) == testCountryCodeWithPlus
                expect(phoneNumber?.normalizedValue.number) == testNumber
            }

            it("Should leave number with + intact") {
                let phoneNumber = PhoneNumber(countryCode: testCountryCodeWithPlus, number: testNumber)
                expect(phoneNumber?.normalizedString) == expectedNumber
                expect(phoneNumber?.normalizedValue.countryCode) == testCountryCodeWithPlus
                expect(phoneNumber?.normalizedValue.number) == testNumber
            }

            it("Should strip 00 and add a +") {
                let phoneNumber = PhoneNumber(countryCode: testCountryCodeWith00, number: testNumber)
                expect(phoneNumber?.normalizedString) == expectedNumber
                expect(phoneNumber?.normalizedValue.countryCode) == testCountryCodeWithPlus
                expect(phoneNumber?.normalizedValue.number) == testNumber
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
                expect(PhoneNumber(countryCode: "+47", number: testNumerWithSpaces)?.normalizedString) == expectedNumber
            }
        }
    }
}
