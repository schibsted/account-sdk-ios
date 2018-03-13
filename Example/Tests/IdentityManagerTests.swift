//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Mockingjay
import Nimble
import Quick
@testable import SchibstedAccount

class IdentityManagerTests: QuickSpec {

    let testNumber = Identifier(PhoneNumber(countryCode: "+47", number: "12345678")!)
    let testEmail = Identifier(EmailAddress("bubble@fart.rules")!)
    let passwordlessToken = PasswordlessToken("token")
    let testPassword = "sour-greapes-make-you-regurgitate"
    let testAuthCode = "123"
    let testLegacyUserID = "5959"
    let locale = Locale.canonicalLanguageIdentifier(from: Locale.current.identifier)

    override func spec() {

        describe("Setting delegate") {

            it("Should not set loggedin state if user valid") {
                Utils.createDummyKeychain()
                let delegate = TestingIdentityManagerDelegate()
                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedIn))
                identityManager.delegate = delegate
                expect(delegate.recordedState).to(beNil())
            }

            it("Should not set loggedin state if user invalid") {
                let delegate = TestingIdentityManagerDelegate()
                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))
                identityManager.delegate = delegate
                expect(delegate.recordedState).to(beNil())
            }

            it("Should not dispatch login event if event occurs before delegate is set") {
                Utils.createDummyKeychain()
                let delegate = TestingIdentityManagerDelegate()
                delegate.recordedState = .loggedIn
                let identityManager = Utils.makeIdentityManager()
                identityManager.currentUser.logout()
                identityManager.delegate = delegate
                expect(delegate.recordedState).toNotEventually(equal(UserState.loggedOut))
            }
        }

        describe("Keychain management") {
            it("Should not treat the user as logged in if it does not find keychain data") {
                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))
            }

            it("Should treat the user as logged in if it finds keychain data") {
                Utils.createDummyKeychain()
                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedIn))
            }

            it("Should update keychain when user is refreshed") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "valid-refresh", status: 200))
                var newTokens: TokenData?
                do {
                    Utils.createDummyKeychain()
                    let identityManager = Utils.makeIdentityManager()
                    identityManager.currentUser.refresh { _ in }
                    newTokens = identityManager.currentUser.tokens
                }

                let tokens = UserTokensKeychain().data().first
                expect(newTokens?.accessToken).to(equal(tokens?.accessToken))
                expect(newTokens?.refreshToken).to(equal(tokens?.refreshToken))
                expect(newTokens?.idToken).to(equal(tokens?.idToken))
            }
        }

        describe("Send code for passwordless signup") {
            it("Should set the proper tokens in token store when all is good") {
                self.stub(uri("/passwordless/start"), try! Builders.load(file: "valid-passwordless", status: 200))
                let identityManager = Utils.makeIdentityManager()

                identityManager.sendCode(to: self.testNumber, completion: { _ in })

                let data = try! PasswordlessTokenStore.getData(for: .sms)

                expect(data.identifier) == self.testNumber
                expect(data.token) == self.passwordlessToken
            }

            it("Should pass in correct form data with sms") {
                self.stub(uri(Router.passwordlessStart.path), http(200))
                let identityManager = Utils.makeIdentityManager()

                identityManager.sendCode(to: self.testNumber, completion: { _ in })

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["email"]).to(beNil())
                expect(callData.passedFormData?["phone_number"]) == self.testNumber.normalizedString
                expect(callData.passedFormData?["client_id"]).to(equal(ClientConfiguration.testing.clientID))
                expect(callData.passedFormData?["connection"]).to(equal("sms"))
                expect(callData.passedFormData?["locale"]).to(equal(self.locale))
            }

            it("Should pass in correct form data with email") {
                self.stub(uri(Router.passwordlessStart.path), http(200))
                let identityManager = Utils.makeIdentityManager()

                identityManager.sendCode(to: self.testEmail, completion: { _ in })

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["phone_number"]).to(beNil())
                expect(callData.passedFormData?["email"]) == self.testEmail.normalizedString
                expect(callData.passedFormData?["client_id"]).to(equal(ClientConfiguration.testing.clientID))
                expect(callData.passedFormData?["connection"]).to(equal("email"))
                expect(callData.passedFormData?["locale"]).to(equal(self.locale))
            }

            it("Should handle network errors") {
                let error = NSError(domain: "Network error", code: 0, userInfo: nil)
                self.stub(uri("/passwordless/start"), failure(error))
                let identityManager = Utils.makeIdentityManager()

                identityManager.sendCode(to: self.testNumber) { result in
                    expect(result).to(failWith(.networkingError(error)))
                }
            }

            it("Should handle when phone number invalid") {
                self.stub(uri("/passwordless/start"), try! Builders.load(file: "invalid-phone-number-error", status: 400))
                let identityManager = Utils.makeIdentityManager()

                identityManager.sendCode(to: self.testNumber) { result in
                    expect(result).to(failWith(ClientError.invalidPhoneNumber))
                }
            }

            it("Should report invalid e-mail error") {
                self.stub(uri("/passwordless/start"), try! Builders.load(file: "invalid-email-error", status: 400))
                let identityManager = Utils.makeIdentityManager()

                identityManager.sendCode(to: self.testEmail) { result in
                    expect(result).to(failWith(ClientError.invalidEmail))
                }
            }

            it("Should report too many requests error") {
                self.stub(uri("/passwordless/start"), try! Builders.load(file: "too-many-requests", status: 429))
                let identityManager = Utils.makeIdentityManager()

                identityManager.sendCode(to: self.testNumber) { result in
                    expect(result).to(failWith(ClientError.tooManyRequests))
                }
            }

            it("Should handle when the passwordless_token is missing") {
                self.stub(uri("/passwordless/start"), try! Builders.load(file: "empty", status: 200))
                let identityManager = Utils.makeIdentityManager()

                identityManager.sendCode(to: self.testNumber) { result in
                    expect(result).to(failWith(.unexpected(JSONError.noKey("passwordless_token"))))
                }
            }
        }

        describe("Validating one time code") {

            it("Should maintain logged out state when code is invalid") {
                self.stub(uri("/oauth/ro"), try! Builders.load(file: "invalid-authcode", status: 400))
                let identityManager = Utils.makeIdentityManager()
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)

                identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: false, completion: { _ in })

                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))
            }

            it("Should set the access token if the correct auth code is provided") {
                self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode", status: 200))
                let identityManager = Utils.makeIdentityManager()

                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)

                expect(identityManager.currentUser.tokens?.accessToken).to(beNil())

                identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: false) { result in
                    expect(result).to(beSuccess())
                }

                expect(identityManager.currentUser.tokens?.accessToken).toNot(beNil())
                expect(identityManager.currentUser.state).to(equal(UserState.loggedIn))
            }

            it("Should error when identifier doesn't exist") {
                let actual = Identifier(PhoneNumber(countryCode: "+4", number: "56")!)
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                let identityManager = Utils.makeIdentityManager()

                identityManager.validate(oneTimeCode: "123", for: actual, persistUser: false) { result in
                    expect(result).to(failWith(ClientError.unexpectedIdentifier(actual: actual, expected: self.testNumber.normalizedString)))
                }
            }

            it("Should ensure user is logged in on next session if login is persistent") {
                do {
                    self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode", status: 200))
                    PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                    let identityManager = Utils.makeIdentityManager()
                    identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: true, completion: { _ in })
                }

                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedIn))
            }

            it("Should ensure user is not logged in on next session if login is not persistent") {
                do {
                    self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode", status: 200))
                    PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                    let identityManager = Utils.makeIdentityManager()
                    identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: false, completion: { _ in })
                }

                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))
            }

            it("Should delegate a logged in event") {
                let delegate = TestingIdentityManagerDelegate()
                let identityManager = Utils.makeIdentityManager()
                identityManager.delegate = delegate

                self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode", status: 200))
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: false, completion: { _ in })

                expect(delegate.recordedState).toEventually(equal(UserState.loggedIn))
            }

            it("Should not delegate a logged in event if already logged in") {
                let delegate = TestingIdentityManagerDelegate()
                let identityManager = Utils.makeIdentityManager()
                identityManager.delegate = delegate

                self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode", status: 200))
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: false, completion: { _ in })

                // Now set state to anything but LoggedIn and make sure it doesn't turn in to LoggedIn
                delegate.recordedState = .loggedOut

                // Set data again because it's removed after previous successful validation
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: false, completion: { _ in })
                expect(delegate.recordedState).toNotEventually(equal(UserState.loggedIn))
            }

            it("Should not delegate logged in event if already logged in and id the same") {
                let delegate = TestingIdentityManagerDelegate()
                let identityManager = Utils.makeIdentityManager()
                identityManager.delegate = delegate

                self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode", status: 200))
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: false, completion: { _ in })

                expect(delegate.recordedState).toEventually(equal(UserState.loggedIn))

                delegate.recordedState = .loggedOut
                self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode-same-id-diff-code", status: 200))
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: false, completion: { _ in })
                expect(delegate.recordedState).toNotEventually(equal(UserState.loggedIn))
            }

            it("Should delegate a logged in event if already logged in and id different") {
                let delegate = TestingIdentityManagerDelegate()
                let identityManager = Utils.makeIdentityManager()
                identityManager.delegate = delegate

                self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode", status: 200))
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: false, completion: { _ in })

                expect(delegate.recordedState).toEventually(equal(UserState.loggedIn))

                delegate.recordedState = .loggedOut
                self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode-diff-id-same-code", status: 200))
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: false, completion: { _ in })
                expect(delegate.recordedState).toEventually(equal(UserState.loggedIn))
            }

            it("Should clean token store after validation") {
                self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode", status: 200))
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                let identityManager = Utils.makeIdentityManager()
                identityManager.validate(oneTimeCode: "123", for: self.testNumber, persistUser: false, completion: { _ in })
                expect { try PasswordlessTokenStore.getData(for: .sms) }.to(throwError())
                expect { try PasswordlessTokenStore.getData(for: .email) }.to(throwError())
            }

            it("Should use whichever identifier works if identifier not provided") {
                self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode", status: 200))
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                let identityManager = Utils.makeIdentityManager()
                identityManager.validate(oneTimeCode: "123", persistUser: false) { result in
                    expect(result).to(beSuccess())
                }
            }

            it("Should fail if no identifier present when identifier not provided") {
                self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode", status: 200))
                let identityManager = Utils.makeIdentityManager()
                identityManager.validate(oneTimeCode: "123", persistUser: false) { result in
                    struct NothingToValidate: Error {}
                    expect(result).to(failWith(ClientError.unexpected(NothingToValidate())))
                }
            }

            it("Should fail if both identifiers present but http call fails for both") {
                self.stub(uri("/oauth/ro"), Builders.load(string: "", status: 400))
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testEmail, for: .email)
                let identityManager = Utils.makeIdentityManager()
                identityManager.validate(oneTimeCode: "123", persistUser: false) { result in
                    let expectedError = ClientError.networkingError(NetworkingError.unexpectedStatus(status: 400, data: "".data(using: .utf8)!))
                    expect(result).to(failWith(expectedError))
                }
            }

            it("Should pass in correct form data") {
                self.stub(uri(Router.validate.path), http(200))
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                let identityManager = Utils.makeIdentityManager()

                identityManager.validate(oneTimeCode: self.testAuthCode, for: self.testNumber, persistUser: false, completion: { _ in })

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["client_id"]).to(equal(ClientConfiguration.testing.clientID))
                expect(callData.passedFormData?["identifier"]) == self.testNumber.normalizedString
                expect(callData.passedFormData?["code"]).to(equal(self.testAuthCode))
                expect(callData.passedFormData?["passwordless_token"]).to(equal(self.passwordlessToken.description))
                expect(callData.passedFormData?["scope"]).to(equal("openid"))
            }

            it("Should handle network errors") {
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                let error = NSError(domain: "Network error", code: 0, userInfo: nil)
                self.stub(uri("/oauth/ro"), failure(error))

                let identityManager = Utils.makeIdentityManager()

                identityManager.validate(oneTimeCode: self.testAuthCode, for: self.testNumber, persistUser: false) { result in
                    expect(result).to(failWith(.networkingError(error)))
                }
            }

            it("Should handle when the access_token is missing") {
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                self.stub(uri("/oauth/ro"), try! Builders.load(file: "invalid-authcode-no-access-token", status: 200))
                let identityManager = Utils.makeIdentityManager()

                identityManager.validate(oneTimeCode: "whatevs", for: self.testNumber, persistUser: false) { result in
                    expect(result).to(failWith(.unexpected(JSONError.noKey("access_token"))))
                }
            }

            it("Should set tokens") {
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                self.stub(uri("/oauth/ro"), try! Builders.load(file: "valid-authcode", status: 200))
                let identityManager = Utils.makeIdentityManager()

                identityManager.validate(oneTimeCode: "whatevs", for: self.testNumber, persistUser: false, completion: { _ in })

                let tokens = identityManager.currentUser.tokens

                expect(tokens?.accessToken).to(equal("123"))
                expect(tokens?.refreshToken).to(equal("abc"))
                expect(tokens?.idToken).to(equal("xyz"))
                expect(tokens?.userID).to(equal("legacy101"))
            }

            it("Should handle when code is invalid") {
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                self.stub(uri("/oauth/ro"), try! Builders.load(file: "invalid-authcode", status: 400))
                let identityManager = Utils.makeIdentityManager()

                identityManager.validate(oneTimeCode: "whatevs", for: self.testNumber, persistUser: false) { result in
                    expect(result).to(failWith(ClientError.invalidCode))
                }
            }
        }

        describe("Log out") {

            it("Should delegate a logged out event") {
                Utils.createDummyKeychain()
                let delegate = TestingIdentityManagerDelegate()
                let identityManager = Utils.makeIdentityManager()
                identityManager.delegate = delegate
                expect(delegate.recordedState).to(beNil())
                identityManager.currentUser.logout()
                expect(delegate.recordedState).toEventually(equal(UserState.loggedOut))
            }

            it("Should not delegate a logged out event if already logged out") {
                let delegate = TestingIdentityManagerDelegate()
                let identityManager = Utils.makeIdentityManager()
                identityManager.delegate = delegate
                expect(delegate.recordedState).to(beNil())

                // Now set state to anything but LoggedOut and make sure it doesn't turn in to LoggedOut
                delegate.recordedState = .loggedIn
                identityManager.currentUser.logout()
                expect(delegate.recordedState).toNotEventually(equal(UserState.loggedOut))
            }

            it("Should clear the currentUser access token") {
                Utils.createDummyKeychain()

                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedIn))
                expect(identityManager.currentUser.tokens?.accessToken).toNot(beNil())

                identityManager.currentUser.logout()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))
                expect(identityManager.currentUser.tokens?.accessToken).to(beNil())
            }

            it("Should remove keychain data") {
                Utils.createDummyKeychain()

                var identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedIn))

                identityManager.currentUser.logout()

                // for reload of they keychain
                identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))
                expect(identityManager.currentUser.tokens?.accessToken).to(beNil())
            }

            it("Should set currentUser to invalid") {
                Utils.createDummyKeychain()
                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedIn))
                identityManager.currentUser.logout()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))
            }

            it("Should result in invalid currentUser if IdentityManager is created after the fact") {
                do {
                    Utils.createDummyKeychain()
                    let identityManager = Utils.makeIdentityManager()
                    expect(identityManager.currentUser.state).to(equal(UserState.loggedIn))
                    identityManager.currentUser.logout()
                }

                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))
            }
        }

        describe("Resending") {

            it("Should fail if different passwordless token returned") {
                self.stub(uri("/passwordless/resend"), try! Builders.load(file: "valid-passwordless", status: 200))
                let identityManager = Utils.makeIdentityManager()
                PasswordlessTokenStore.setData(token: PasswordlessToken("IAmDifferentFromCanned"), identifier: self.testNumber, for: .sms)
                identityManager.resendCode(to: self.testNumber) { result in
                    expect(result).to(failWith(ClientError.unexpected(GenericError.Unexpected("passwordless tokens mismatch"))))
                }
            }

            it("Should succeed if correct passwordless token returned") {
                self.stub(uri("/passwordless/resend"), try! Builders.load(file: "valid-passwordless", status: 200))
                let identityManager = Utils.makeIdentityManager()
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                identityManager.resendCode(to: self.testNumber) { result in
                    expect(result).to(beSuccess())
                }
            }

            it("Should fail if identifier incorrect") {
                self.stub(uri("/passwordless/resend"), try! Builders.load(file: "valid-passwordless", status: 200))
                let identityManager = Utils.makeIdentityManager()
                let expected = Identifier(PhoneNumber(countryCode: "+1", number: "23")!)
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: expected, for: .sms)
                identityManager.resendCode(to: self.testNumber) { result in
                    expect(result).to(failWith(ClientError.unexpectedIdentifier(actual: self.testNumber, expected: expected.normalizedString)))
                }
            }

            it("Should pass in correct form data") {
                self.stub(uri(Router.passwordlessResend.path), http(200))
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                let identityManager = Utils.makeIdentityManager()

                identityManager.resendCode(to: self.testNumber, completion: { _ in })

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["client_id"]).to(equal(ClientConfiguration.testing.clientID))
                expect(callData.passedFormData?["passwordless_token"]).to(equal(self.passwordlessToken.description))
                expect(callData.passedFormData?["locale"]).to(equal(self.locale))
            }

            it("Should handle network errors") {
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                let error = NSError(domain: "Network error", code: 0, userInfo: nil)
                self.stub(uri("/passwordless/resend"), failure(error))
                let identityManager = Utils.makeIdentityManager()

                identityManager.resendCode(to: self.testNumber) { result in
                    expect(result).to(failWith(.networkingError(error)))
                }
            }

            it("Should handle when the passwordless_token is missing") {
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                self.stub(uri("/passwordless/resend"), try! Builders.load(file: "empty", status: 200))
                let identityManager = Utils.makeIdentityManager()

                identityManager.resendCode(to: self.testNumber) { result in
                    expect(result).to(failWith(.unexpected(JSONError.noKey("passwordless_token"))))
                }
            }

            it("Should return passwordless token") {
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                self.stub(uri("/passwordless/resend"), try! Builders.load(file: "valid-passwordless", status: 200))
                let identityManager = Utils.makeIdentityManager()

                identityManager.resendCode(to: self.testNumber, completion: { _ in })

                let data = try? PasswordlessTokenStore.getData(for: .sms)

                expect(data).toNot(beNil())
                expect(data?.token).to(equal(self.passwordlessToken))
            }

            it("Should handle when phone number invalid") {
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                self.stub(uri("/passwordless/resend"), try! Builders.load(file: "invalid-phone-number-error", status: 400))
                let identityManager = Utils.makeIdentityManager()

                identityManager.resendCode(to: self.testNumber) { result in
                    expect(result).to(failWith(ClientError.invalidPhoneNumber))
                }
            }

            it("Should report invalid e-mail error") {
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testEmail, for: .email)
                self.stub(uri("/passwordless/resend"), try! Builders.load(file: "invalid-email-error", status: 400))
                let identityManager = Utils.makeIdentityManager()

                identityManager.resendCode(to: self.testEmail) { result in
                    expect(result).to(failWith(ClientError.invalidEmail))
                }
            }

            it("Should report too many requests error") {
                PasswordlessTokenStore.setData(token: self.passwordlessToken, identifier: self.testNumber, for: .sms)
                self.stub(uri("/passwordless/resend"), try! Builders.load(file: "too-many-requests", status: 429))
                let identityManager = Utils.makeIdentityManager()

                identityManager.resendCode(to: self.testNumber) { result in
                    expect(result).to(failWith(ClientError.tooManyRequests))
                }
            }
        }

        describe("Login with password") {
            it("Should pass in a credential") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "login-valid", status: 200))

                let identityManager = Utils.makeIdentityManager()

                identityManager.login(username: self.testEmail, password: self.testPassword, persistUser: false, completion: { _ in })

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["username"]) == self.testEmail.normalizedString
                expect(callData.passedFormData?["password"]).to(equal(self.testPassword))
                expect(callData.passedFormData?["scope"]).to(equal("openid"))
            }

            it("Should change state to be logged in") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "login-valid", status: 200))
                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))

                identityManager.login(username: self.testEmail, password: self.testPassword, persistUser: false, completion: { _ in })

                expect(identityManager.currentUser.state).to(equal(UserState.loggedIn))
            }

            it("Should set auth tokens") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "login-valid", status: 200))
                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.tokens).to(beNil())

                identityManager.login(username: self.testEmail, password: self.testPassword, persistUser: false, completion: { _ in })

                expect(identityManager.currentUser.tokens).toNot(beNil())
                expect(identityManager.currentUser.tokens?.accessToken).to(equal("d315d41a1804dc7416accb7a02410eeff7a078c7"))
                expect(identityManager.currentUser.tokens?.refreshToken).to(equal("19242f0cffbc140fa39248143d785b3fd462db74"))
                expect(identityManager.currentUser.tokens?.userID).to(equal("3502"))
            }

            it("Should set id token if present") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "login-valid-with-id-token", status: 200))
                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.tokens?.idToken).to(beNil())

                identityManager.login(username: self.testEmail, password: self.testPassword, persistUser: false, completion: { _ in })

                expect(identityManager.currentUser.tokens?.idToken).to(equal("testIDToken"))
            }

            it("Should parse subjectID from id token if present") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "login-valid-with-id-token", status: 200))
                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.id).to(beNil())

                identityManager.login(username: self.testEmail, password: self.testPassword, persistUser: false, completion: { _ in })

                expect(identityManager.currentUser.id).to(equal("testIDToken"))
            }

            it("Should report an error on invalid password") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "login-invalid-password", status: 400))
                let identityManager = Utils.makeIdentityManager()
                var errorMaybe: Error?

                identityManager.login(username: self.testEmail, password: self.testPassword, persistUser: false) { result in
                    expect(result).to(failWith(ClientError.invalidUserCredentials(message: nil)))
                }
            }

            it("Should stay logged out on invalid password") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "login-invalid-password", status: 400))
                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))

                identityManager.login(username: self.testEmail, password: self.testPassword, persistUser: false, completion: { _ in })

                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))
            }

            it("Should return unverifiedEmail error when it is unverified") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "login-invalid-unverified", status: 400))
                let identityManager = Utils.makeIdentityManager()

                identityManager.login(username: self.testEmail, password: self.testPassword, persistUser: false) { result in
                    expect(result).to(failWith(ClientError.unverifiedEmail))
                }
            }
        }

        describe("Signup") {
            it("Should receive client access token as obtained") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "signup-client-access-token", status: 200))
                self.stub(uri("/api/2/signup"), try! Builders.load(file: "signup-valid", status: 201))

                let identityManager = Utils.makeIdentityManager()
                identityManager.signup(username: self.testEmail, password: self.testPassword, persistUser: false, completion: { _ in })

                expect(Networking.testingProxy.callCount).to(equal(2))
                let callData = Networking.testingProxy.calls.last
                expect(callData?.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain("mytestcat555"))
            }

            it("Should receive email and password") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "signup-client-access-token", status: 200))
                self.stub(uri("/api/2/signup"), try! Builders.load(file: "signup-valid", status: 201))

                let identityManager = Utils.makeIdentityManager()
                identityManager.signup(username: self.testEmail, password: self.testPassword, persistUser: false, completion: { _ in })

                let callData = Networking.testingProxy.calls.last
                expect(callData?.passedFormData?["email"]) == self.testEmail.normalizedString
                expect(callData?.passedFormData?["password"]).to(equal(self.testPassword))
            }

            it("Should have correct redirect uri with default scheme") {
                let configuration = ClientConfiguration(
                    serverURL: URL(string: "http://localhost:5050")!,
                    clientID: "123",
                    clientSecret: "123",
                    appURLScheme: nil
                )
                self.stub(uri("/oauth/token"), try! Builders.load(file: "signup-client-access-token", status: 200))
                self.stub(uri("/api/2/signup"), try! Builders.load(file: "signup-valid", status: 201))

                let identityManager = Utils.makeIdentityManager(clientConfiguration: configuration)
                identityManager.signup(username: self.testEmail, password: self.testPassword, persistUser: false, completion: { _ in })

                let callData = Networking.testingProxy.calls.last
                let redirectUri = URL(string: callData!.passedFormData!["redirectUri"]!)
                expect(redirectUri?.scheme) == configuration.appURLScheme
                expect(redirectUri?.host) == configuration.redirectURLRoot
                expect(redirectUri?.query) == "persist-user=false&path=validate-after-signup"
            }

            it("Should have correct redirect uri with custom scheme") {
                let configuration = ClientConfiguration.testing
                self.stub(uri("/oauth/token"), try! Builders.load(file: "signup-client-access-token", status: 200))
                self.stub(uri("/api/2/signup"), try! Builders.load(file: "signup-valid", status: 201))

                let identityManager = Utils.makeIdentityManager(clientConfiguration: configuration)
                identityManager.signup(username: self.testEmail, password: self.testPassword, persistUser: false, completion: { _ in })

                let callData = Networking.testingProxy.calls.last
                let redirectUri = URL(string: callData!.passedFormData!["redirectUri"]!)
                expect(redirectUri?.scheme) == configuration.appURLScheme
                expect(redirectUri?.pathComponents[1]) == configuration.redirectURLRoot
                expect(redirectUri?.query) == "persist-user=false&path=validate-after-signup"
            }

            it("Should report an error on bad email") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "signup-client-access-token", status: 200))
                // TODO: this is kinda wrong, but this is what we get ATM (see https://jira.schibsted.io/browse/ID-1524 )
                self.stub(uri("/api/2/signup"), try! Builders.load(file: "signup-invalid-duplicate-email", status: 302))

                let identityManager = Utils.makeIdentityManager()
                identityManager.signup(username: self.testEmail, password: self.testPassword, persistUser: false) { result in
                    expect(result).to(failWith(ClientError.alreadyRegistered(message: "kowabunga")))
                }
            }

            it("Should report an error on bad password") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "signup-client-access-token", status: 200))
                self.stub(uri("/api/2/signup"), try! Builders.load(file: "signup-invalid-bad-password", status: 409))

                let identityManager = Utils.makeIdentityManager()
                identityManager.signup(username: self.testEmail, password: self.testPassword, persistUser: false) { result in
                    // TODO: Is this correct? Should there be a ClientError enum for this?
                    expect(result).to(beFailure())
                }
            }

            it("Should report an error on duplicate email") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "signup-client-access-token", status: 200))
                self.stub(uri("/api/2/signup"), try! Builders.load(file: "signup-invalid-duplicate-email", status: 302))

                let identityManager = Utils.makeIdentityManager()
                identityManager.signup(username: self.testEmail, password: self.testPassword, persistUser: false) { result in
                    expect(result).to(failWith(ClientError.alreadyRegistered(message: "kowabunga")))
                }
            }
        }

        describe("Signup email validation") {
            it("Should change to logged in state") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "signup-validation-valid", status: 200))
                let identityManager = Utils.makeIdentityManager()
                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))

                identityManager.validate(authCode: self.testAuthCode, persistUser: false, completion: { _ in })

                expect(identityManager.currentUser.state).to(equal(UserState.loggedIn))
            }

            it("Should set auth tokens") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "signup-validation-valid", status: 200))
                let identityManager = Utils.makeIdentityManager()
                identityManager.validate(authCode: self.testAuthCode, persistUser: false, completion: { _ in })

                expect(identityManager.currentUser.tokens).toNot(beNil())
                expect(identityManager.currentUser.tokens?.accessToken).to(equal("mytesttkn111"))
                expect(identityManager.currentUser.tokens?.refreshToken).to(equal("cb4e56131247688b1460479b7406eab2ca0de932"))
            }

            it("Should report an error on invalid code") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "signup-validation-invalid", status: 400))
                let identityManager = Utils.makeIdentityManager()
                identityManager.validate(authCode: self.testAuthCode, persistUser: false) { result in
                    expect(result).to(failWith(ClientError.invalidCode))
                }
            }

            it("Should stay logged out on invalid code") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "signup-validation-invalid", status: 400))
                let identityManager = Utils.makeIdentityManager()
                identityManager.validate(authCode: self.testAuthCode, persistUser: false, completion: { _ in })

                expect(identityManager.currentUser.state).to(equal(UserState.loggedOut))
            }
        }

        describe("Identifier status checks") {
            // this custom matcher is used, because
            // the URITemplate matcher with parameters doesn't allow for "=" character,
            // which is a valid character for base64-encoded identifiers
            func statusAPIRequestMatcher(_ request: URLRequest) -> Bool {
                return request.url?.path.hasSuffix("/status") ?? false
            }

            it("Should receive client access token as obtained") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "client-access-token-valid", status: 200))
                self.stub(statusAPIRequestMatcher, try! Builders.load(file: "id-status-valid-verified", status: 200))

                let identityManager = Utils.makeIdentityManager()
                identityManager.fetchStatus(for: self.testEmail, completion: { _ in })

                expect(Networking.testingProxy.callCount).to(equal(2))
                let callData = Networking.testingProxy.calls.last
                expect(callData?.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain("123"))
            }

            it("Should fail without client access token") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "client-access-token-invalid", status: 400))
                let identityManager = Utils.makeIdentityManager()
                identityManager.fetchStatus(for: self.testEmail) { result in
                    expect(result).to(failWith(ClientError.invalidClientCredentials))
                    expect(Networking.testingProxy.callCount).to(equal(1))
                }
            }

            it("Should get correct status - verified") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "client-access-token-valid", status: 200))
                self.stub(statusAPIRequestMatcher, try! Builders.load(file: "id-status-valid-verified", status: 200))

                let identityManager = Utils.makeIdentityManager()
                identityManager.fetchStatus(for: self.testEmail) { result in
                    expect(result).to(succeedWith(IdentifierStatus(verified: true, exists: false, available: false)))
                }
            }

            it("Should get correct status - available") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "client-access-token-valid", status: 200))
                self.stub(statusAPIRequestMatcher, try! Builders.load(file: "id-status-valid-available", status: 200))

                let identityManager = Utils.makeIdentityManager()
                identityManager.fetchStatus(for: self.testEmail) { result in
                    expect(result).to(succeedWith(IdentifierStatus(verified: false, exists: false, available: true)))
                }
            }
        }

        describe("Agreements links") {
            it("Should return the links") {
                let identityManager = Utils.makeIdentityManager()
                self.stub(uri("/api/2/terms"), try! Builders.load(file: "agreements-text-valid", status: 200))

                identityManager.fetchTerms { result in
                    guard case let .success(links) = result else {
                        return fail()
                    }
                    expect(links.platformPrivacyURL).to(equal(URL(string: "https://environment.baseURL.com/privacy")!))
                    expect(links.platformTermsURL).to(equal(URL(string: "https://environment.baseURL.com/about/terms")!))
                    expect(links.clientPrivacyURL).to(equal(URL(string: "https://clientID.client-website-url.com/privacy-link")!))
                    expect(links.clientTermsURL).to(equal(URL(string: "https://environment.baseURL.com/terms/clientID")!))
                }
            }
        }
    }
}
