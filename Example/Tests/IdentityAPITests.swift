//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Mockingjay
import Nimble
import Quick
@testable import SchibstedAccount

class IdentityAPITests: QuickSpec {

    let testNumber = "+4712345678"
    let testEmail = "email@example.com"
    let testEmailContainingPlus = "email+test@example.com"
    let testAuthCode = "testAuthCode"
    let testPasswordlessToken = PasswordlessToken("testPasswordlessToken")
    let testRefreshToken = "testRefreshToken"
    let testClientID = "clientId"
    let testClientSecret = "clientSecret"
    let testOauthToken = "oauth"
    let testUserID = "userID"
    let testLocale = Locale.canonicalLanguageIdentifier(from: Locale.current.identifier)
    let testBasePath = URL(string: "http://localhost:5050")!

    override func spec() {
        describe("start passwordless") {
            it("Should pass in correct form data with sms") {
                self.stub(uri(Router.passwordlessStart.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.startPasswordless(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        locale: self.testLocale,
                        identifier: self.testNumber,
                        connection: .sms
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["email"]).to(beNil())
                expect(callData.passedFormData?["phone_number"]) == self.testNumber
                expect(callData.passedFormData?["client_id"]).to(equal(self.testClientID))
                expect(callData.passedFormData?["client_secret"]).to(equal(self.testClientSecret))
                expect(callData.passedFormData?["connection"]).to(equal("sms"))
                expect(callData.passedFormData?["locale"]).to(equal(self.testLocale))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }

            it("Should pass in correct form data with email") {
                self.stub(uri(Router.passwordlessStart.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.startPasswordless(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        locale: self.testLocale,
                        identifier: self.testEmail,
                        connection: .email
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["phone_number"]).to(beNil())
                expect(callData.passedFormData?["email"]) == self.testEmail
                expect(callData.passedFormData?["client_id"]).to(equal(self.testClientID))
                expect(callData.passedFormData?["connection"]).to(equal("email"))
                expect(callData.passedFormData?["locale"]).to(equal(self.testLocale))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }

            it("Should pass in correct form data with email containing plus character") {
                self.stub(uri(Router.passwordlessStart.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.startPasswordless(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        locale: self.testLocale,
                        identifier: self.testEmailContainingPlus,
                        connection: .email
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["phone_number"]).to(beNil())
                expect(callData.passedFormData?["email"]) == self.testEmailContainingPlus
                expect(callData.passedFormData?["client_id"]).to(equal(self.testClientID))
                expect(callData.passedFormData?["connection"]).to(equal("email"))
                expect(callData.passedFormData?["locale"]).to(equal(self.testLocale))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }

            it("Should handle network errors") {
                let expectedError = NSError(domain: "Network error", code: 0, userInfo: nil)
                self.stub(uri(Router.passwordlessStart.path), failure(expectedError))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.startPasswordless(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        locale: self.testLocale,
                        identifier: self.testNumber,
                        connection: .sms
                    ) { result in
                        expect(result).to(failWith(ClientError.networkingError(expectedError)))
                        done()
                    }
                }
            }

            it("Should handle when phone number invalid") {
                self.stub(uri(Router.passwordlessStart.path), try! Builders.load(file: "invalid-phone-number-error", status: 400))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.startPasswordless(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        locale: self.testLocale,
                        identifier: self.testNumber,
                        connection: .sms
                    ) { result in
                        expect(result).to(failWith(ClientError.invalidPhoneNumber))
                        done()
                    }
                }
            }

            it("Should handle when the passwordless_token is missing") {
                self.stub(uri(Router.passwordlessStart.path), try! Builders.load(file: "empty", status: 200))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.startPasswordless(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        locale: self.testLocale,
                        identifier: self.testNumber,
                        connection: .sms
                    ) { result in
                        expect(result).to(failWith(.unexpected(JSONError.noKey("passwordless_token"))))
                        done()
                    }
                }
            }

            it("Should return passwordless token") {
                self.stub(uri(Router.passwordlessStart.path), try! Builders.load(file: "valid-passwordless", status: 200))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.startPasswordless(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        locale: self.testLocale,
                        identifier: self.testNumber,
                        connection: .sms
                    ) { result in
                        expect(result).to(succeedWith(PasswordlessToken("token")))
                        done()
                    }
                }
            }
        }

        describe("validate") {
            it("Should pass in correct form data") {
                self.stub(uri(Router.validate.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.validateCode(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        identifier: self.testNumber,
                        connection: .sms,
                        code: self.testAuthCode,
                        passwordlessToken: self.testPasswordlessToken,
                        scope: ["openid"]
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["client_id"]) == self.testClientID
                expect(callData.passedFormData?["identifier"]) == self.testNumber
                expect(callData.passedFormData?["code"]) == self.testAuthCode
                expect(callData.passedFormData?["passwordless_token"]) == String(describing: self.testPasswordlessToken)
                expect(callData.passedFormData?["scope"]) == "openid"
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }

            it("Should handle network errors") {
                let expectedError = NSError(domain: "Network error", code: 0, userInfo: nil)
                self.stub(uri(Router.validate.path), failure(expectedError))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.validateCode(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        identifier: self.testNumber,
                        connection: .sms,
                        code: self.testAuthCode,
                        passwordlessToken: self.testPasswordlessToken,
                        scope: ["openid"]
                    ) { result in
                        expect(result).to(failWith(ClientError.networkingError(expectedError)))
                        done()
                    }
                }
            }

            it("Should handle when the access_token is missing") {
                self.stub(uri(Router.validate.path), try! Builders.load(file: "invalid-authcode-no-access-token", status: 200))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.validateCode(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        identifier: self.testNumber,
                        connection: .sms,
                        code: self.testAuthCode,
                        passwordlessToken: self.testPasswordlessToken,
                        scope: ["openid"]
                    ) { result in
                        expect(result).to(failWith(.unexpected(JSONError.noKey("access_token"))))
                        done()
                    }
                }
            }

            it("Should return validate data") {
                self.stub(uri(Router.validate.path), try! Builders.load(file: "valid-authcode", status: 200))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.validateCode(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        identifier: self.testNumber,
                        connection: .sms,
                        code: self.testAuthCode,
                        passwordlessToken: self.testPasswordlessToken,
                        scope: ["openid"]
                    ) { result in
                        expect(result).to(beSuccess())
                        if case let .success(data) = result {
                            expect(data.accessToken).to(equal("123"))
                            expect(data.refreshToken).to(equal("abc"))
                            expect(data.idToken).to(equal("xyz"))
                        }
                        done()
                    }
                }
            }

            it("Should handle when code is invalid") {
                self.stub(uri(Router.validate.path), try! Builders.load(file: "invalid-authcode", status: 400))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.validateCode(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        identifier: self.testNumber,
                        connection: .sms,
                        code: self.testAuthCode,
                        passwordlessToken: self.testPasswordlessToken,
                        scope: ["openid"]
                    ) { result in
                        expect(result).to(failWith(ClientError.invalidCode))
                        done()
                    }
                }
            }
        }

        describe("refresh") {
            it("Should pass in correct form data") {
                self.stub(uri(Router.oauthToken.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.requestAccessToken(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        grantType: .refreshToken,
                        refreshToken: self.testRefreshToken
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["client_id"]).to(equal(self.testClientID))
                expect(callData.passedFormData?["grant_type"]).to(equal("refresh_token"))
                expect(callData.passedFormData?["refresh_token"]).to(equal(self.testRefreshToken))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }

            it("Should handle network errors") {
                let expectedError = NSError(domain: "Network error", code: 0, userInfo: nil)
                self.stub(uri(Router.oauthToken.path), failure(expectedError))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.requestAccessToken(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        grantType: .refreshToken,
                        refreshToken: self.testRefreshToken
                    ) { result in
                        expect(result).to(failWith(ClientError.networkingError(expectedError)))
                        done()
                    }
                }
            }

            it("Should return refresh data") {
                self.stub(uri(Router.oauthToken.path), try! Builders.load(file: "valid-refresh", status: 200))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.requestAccessToken(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        grantType: .refreshToken,
                        refreshToken: self.testRefreshToken
                    ) { result in
                        let tokens = TokenData(accessToken: "123", refreshToken: "abc", idToken: "xyz", userID: nil)
                        expect(result).to(succeedWith(tokens))
                        done()
                    }
                }
            }

            it("Should handle when the access_token is missing") {
                self.stub(uri(Router.oauthToken.path), try! Builders.load(file: "invalid-refresh-no-access-token", status: 200))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.requestAccessToken(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        grantType: .refreshToken,
                        refreshToken: self.testRefreshToken
                    ) { result in
                        expect(result).to(failWith(.unexpected(JSONError.noKey("access_token"))))
                        done()
                    }
                }
            }
        }

        describe("resend") {
            it("Should pass in correct form data") {
                self.stub(uri(Router.passwordlessResend.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.resendCode(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        passwordlessToken: self.testPasswordlessToken,
                        locale: self.testLocale
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["client_id"]) == self.testClientID
                expect(callData.passedFormData?["passwordless_token"]) == String(describing: self.testPasswordlessToken)
                expect(callData.passedFormData?["locale"]) == self.testLocale
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }

            it("Should handle network errors") {
                let expectedError = NSError(domain: "Network error", code: 0, userInfo: nil)
                self.stub(uri(Router.passwordlessResend.path), failure(expectedError))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.resendCode(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        passwordlessToken: self.testPasswordlessToken,
                        locale: self.testLocale
                    ) { result in
                        expect(result).to(failWith(ClientError.networkingError(expectedError)))
                        done()
                    }
                }
            }

            it("Should handle when the passwordless_token is missing") {
                self.stub(uri(Router.passwordlessResend.path), try! Builders.load(file: "empty", status: 200))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.resendCode(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        passwordlessToken: self.testPasswordlessToken,
                        locale: self.testLocale
                    ) { result in
                        expect(result).to(failWith(.unexpected(JSONError.noKey("passwordless_token"))))
                        done()
                    }
                }
            }

            it("Should return passwordless token") {
                self.stub(uri(Router.passwordlessResend.path), try! Builders.load(file: "valid-passwordless", status: 200))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.resendCode(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        passwordlessToken: self.testPasswordlessToken,
                        locale: self.testLocale
                    ) { result in
                        expect(result).to(succeedWith(PasswordlessToken("token")))
                        done()
                    }
                }
            }
        }

        describe("fetchAgreementsAcceptanceStatus") {
            it("should pass in correct data") {
                self.stub(uri(Router.agreementsStatus(userID: self.testUserID).path), http(200))

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.fetchAgreementsAcceptanceStatus(
                        oauthToken: self.testOauthToken,
                        userID: self.testUserID
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(callData.passedUrl?.absoluteString).to(contain(self.testUserID))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }
        }

        describe("acceptAgreements") {
            it("should pass in correct data") {
                self.stub(uri(Router.acceptAgreements(userID: self.testUserID).path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.acceptAgreements(
                        oauthToken: self.testOauthToken,
                        userID: self.testUserID
                    ) { _ in
                        done()
                    }
                }
                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(callData.passedUrl?.absoluteString).to(contain(self.testUserID))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }
        }

        describe("fetchTerms") {
            it("should pass in correct data") {
                self.stub(uri(Router.terms.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.fetchTerms(
                        clientID: self.testClientID
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                let query = URLComponents(url: callData.passedUrl!, resolvingAgainstBaseURL: false)
                let contains = query?.queryItems?.contains(where: { (item) -> Bool in
                    item.name == "client_id" && item.value == self.testClientID
                })
                expect(contains).to(be(true))
            }
        }

        describe("fetchClientAccessToken") {
            it("should pass in correct data") {
                self.stub(uri(Router.oauthToken.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.fetchClientAccessToken(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret
                    ) { _ in
                        done()
                    }
                }
                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedFormData?["client_id"]).to(equal(self.testClientID))
                expect(callData.passedFormData?["client_secret"]).to(equal("clientSecret"))
                expect(callData.passedFormData?["grant_type"]).to(equal("client_credentials"))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }
        }

        describe("fetchIdentifierStatus") {
            it("should pass in correct data on phone") {
                self.stub(uri(Router.identifierStatus(connection: .sms, identifierInBase64: "base64").path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.fetchIdentifierStatus(
                        oauthToken: self.testOauthToken,
                        identifierInBase64: "base64",
                        connection: .sms
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(callData.passedUrl?.absoluteString).to(contain("phone"))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }

            it("should pass in correct data") {
                self.stub(uri(Router.identifierStatus(connection: .email, identifierInBase64: "base64").path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.fetchIdentifierStatus(
                        oauthToken: self.testOauthToken,
                        identifierInBase64: "base64",
                        connection: .email
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(callData.passedUrl?.absoluteString).to(contain("email"))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }
        }

        describe("fetchUserProfile") {
            it("should pass in correct data") {
                self.stub(uri(Router.profile(userID: self.testUserID).path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.fetchUserProfile(
                        userID: self.testUserID,
                        oauthToken: self.testOauthToken
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(callData.passedUrl?.absoluteString).to(contain(self.testUserID))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }
        }

        describe("logout") {
            it("should pass in correct data") {
                self.stub(uri(Router.logout.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.logout(
                        oauthToken: self.testOauthToken
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }
        }

        describe("signup") {
            it("should pass in correct data") {
                self.stub(uri(Router.signup.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.signup(
                        oauthToken: self.testOauthToken,
                        email: self.testEmail,
                        password: "password"
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(callData.passedFormData?["email"]).to(equal(self.testEmail))
                expect(callData.passedFormData?["password"]).to(equal("password"))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }

            it("Should get the usermodel back") {
                self.stub(uri(Router.signup.path), try! Builders.load(file: "signup-valid", status: 201))
                let api = IdentityAPI(basePath: self.testBasePath)
                waitUntil { done in
                    api.signup(
                        oauthToken: self.testOauthToken,
                        email: self.testEmail,
                        password: "password"
                    ) { result in
                        expect(result).to(succeedWith(UserModel(email: "123@monkey.net")))
                        done()
                    }
                }
            }
        }

        describe("tokenExchange") {
            it("should pass in correct data code") {
                self.stub(uri(Router.exchangeToken.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.tokenExchange(
                        oauthToken: self.testOauthToken,
                        clientID: self.testClientID,
                        type: TokenExchangeType.code
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(callData.passedFormData?["clientId"]).to(equal(self.testClientID))
                expect(callData.passedFormData?["type"]).to(equal(TokenExchangeType.code.rawValue))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }

            it("should pass in correct data session") {
                self.stub(uri(Router.exchangeToken.path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.tokenExchange(
                        oauthToken: self.testOauthToken,
                        clientID: self.testClientID,
                        type: TokenExchangeType.session
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(callData.passedFormData?["clientId"]).to(equal(self.testClientID))
                expect(callData.passedFormData?["type"]).to(equal(TokenExchangeType.session.rawValue))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }
        }

        describe("updateUserProfile") {
            it("should pass in correct data") {
                self.stub(uri(Router.updateProfile(userID: self.testUserID).path), http(200))
                let api = IdentityAPI(basePath: self.testBasePath)

                let profile = UserProfile(givenName: "new name")
                waitUntil { done in
                    api.updateUserProfile(
                        userID: self.testUserID,
                        oauthToken: self.testOauthToken,
                        profile: profile
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.calledOnce).to(beTrue())
                let callData = Networking.testingProxy.calls[0]
                expect(callData.passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(callData.passedFormData?["name"]).to(contain("new name"))
                expect(callData.passedUrl?.absoluteString).to(contain(self.testUserID))
                expect(callData.sentHTTPHeaders?[Networking.Header.userAgent.rawValue]).to(equal(UserAgent().value))
                expect(callData.sentHTTPHeaders?[Networking.Header.uniqueUserAgent.rawValue]).to(beNil())
            }

            it("should get the new profile returned") {
                self.stub(uri(Router.updateProfile(userID: self.testUserID).path), try! Builders.load(file: "user-profile-valid", status: 200))

                let api = IdentityAPI(basePath: self.testBasePath)
                let profile = UserProfile(givenName: "Gordon")
                waitUntil { done in
                    api.updateUserProfile(
                        userID: self.testUserID,
                        oauthToken: self.testOauthToken,
                        profile: profile
                    ) { result in
                        expect(result).to(beSuccess())
                        if case let .success(profile) = result {
                            expect(profile.givenName).to(equal("Gordon"))
                        }
                        done()
                    }
                }
            }
        }
    }
}
