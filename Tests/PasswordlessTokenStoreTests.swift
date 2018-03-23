//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class PasswordlessTokenStoreTests: QuickSpec {

    let testToken = PasswordlessToken("test-token")
    let testEmail = Identifier(EmailAddress("hello@adele.listen")!)
    let testCountryCode = "+47"
    let testPhoneNumber = "123456"

    override func spec() {

        describe("Setting data") {

            it("Should get back the same token") {
                PasswordlessTokenStore.setData(token: self.testToken, identifier: self.testEmail, for: .email)
                let data = try? PasswordlessTokenStore.getData(for: .email)
                expect(data?.token).to(equal(self.testToken))
            }

            it("Should get back the same identifier") {
                PasswordlessTokenStore.setData(token: self.testToken, identifier: self.testEmail, for: .email)
                let data = try? PasswordlessTokenStore.getData(for: .email)
                expect(data?.identifier).to(equal(self.testEmail))
            }

            it("Should get back the same phone number") {
                let phoneNumber = PhoneNumber(countryCode: self.testCountryCode, number: self.testPhoneNumber)
                PasswordlessTokenStore.setData(token: self.testToken, identifier: Identifier(phoneNumber!), for: .sms)
                let data = try? PasswordlessTokenStore.getData(for: .sms)
                expect(data?.identifier.normalizedString).to(equal(self.testCountryCode + self.testPhoneNumber))
            }
        }

        describe("Getting data") {

            it("Should throw if no data for an identifier type") {
                expect { try PasswordlessTokenStore.getData(for: .sms) }.to(throwError())
                expect { try PasswordlessTokenStore.getData(for: .email) }.to(throwError())
            }

            it("Should throw if token empty") {
                PasswordlessTokenStore.setData(token: PasswordlessToken(""), identifier: self.testEmail, for: .email)
                expect { try PasswordlessTokenStore.getData(for: .email) }.to(throwError())
            }

            it("Should throw if phone's number is in the old format (i.e. without a separated country code)") {
                Settings.setValue("\(self.testCountryCode)-\(self.testPhoneNumber):\(self.testToken)", forKey: "passwordless-token.sms")
                let data = try? PasswordlessTokenStore.getData(for: .sms)
                expect(data?.identifier.normalizedString).to(equal(self.testCountryCode + self.testPhoneNumber))

                Settings.setValue("\(self.testCountryCode)\(self.testPhoneNumber):\(self.testToken)", forKey: "passwordless-token.sms")
                expect { try PasswordlessTokenStore.getData(for: .email) }.to(throwError())
            }
        }

        describe("Clearing the store") {

            it("Should clear all identifier types data if set") {
                let types: [Connection] = [.sms, .email]
                PasswordlessTokenStore.setData(token: self.testToken, identifier: self.testEmail, for: .email)
                let phoneIdentifier = Identifier(PhoneNumber(countryCode: "+123", number: "456")!)
                PasswordlessTokenStore.setData(token: self.testToken, identifier: phoneIdentifier, for: .sms)
                PasswordlessTokenStore.clear()
                for type in types {
                    let data = try? PasswordlessTokenStore.getData(for: type)
                    expect(data).to(beNil())
                }
            }
        }
    }
}
