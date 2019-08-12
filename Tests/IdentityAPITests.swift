//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

private func haveStandardHeadersSet() -> Predicate<Dictionary<String, String>> {
    return Predicate({ (expression) -> PredicateResult in
        let expected = [
            Networking.Header.userAgent.rawValue: UserAgent().value,
            Networking.Header.xOIDC.rawValue: "true",
            Networking.Header.sdkVersion.rawValue: sdkVersion,
            Networking.Header.sdkType.rawValue: "ios",
        ]
        let unexpected = [
            Networking.Header.xSchibstedAccountUserAgent.rawValue,
        ]
        let msg = ExpectationMessage.expectedActualValueTo("be \(expected)")
        guard let actual = try expression.evaluate() else {
            return PredicateResult(status: .fail, message: msg)
        }

        for key in unexpected where actual.keys.contains(key) {
            return PredicateResult(status: .fail, message: msg)
        }

        for (key, value) in expected where actual[key] != value {
            return PredicateResult(status: .fail, message: msg)
        }

        return PredicateResult(status: .matches, message: msg)
    })
}
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
    let testPassword = "huckleberryfinn"
    let testLocale = Locale.canonicalLanguageIdentifier(from: Locale.current.identifier)
    let testBasePath = URL(string: "http://localhost:5050")!

    override func spec() {
        describe("start passwordless") {
            it("Should pass in correct form data with sms") {
                var stub = NetworkStub(path: .path(Router.passwordlessStart.path))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.formData?["email"]).to(beNil())
                expect(data?.formData?["phone_number"]) == self.testNumber
                expect(data?.formData?["client_id"]).to(equal(self.testClientID))
                expect(data?.formData?["client_secret"]).to(equal(self.testClientSecret))
                expect(data?.formData?["connection"]).to(equal("sms"))
                expect(data?.formData?["locale"]).to(equal(self.testLocale))
                expect(data?.headers).to(haveStandardHeadersSet())
            }

            it("Should pass in correct form data with email") {
                var stub = NetworkStub(path: .path(Router.passwordlessStart.path))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)
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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.formData?["phone_number"]).to(beNil())
                expect(data?.formData?["email"]) == self.testEmail
                expect(data?.formData?["client_id"]).to(equal(self.testClientID))
                expect(data?.formData?["connection"]).to(equal("email"))
                expect(data?.formData?["locale"]).to(equal(self.testLocale))
                expect(data?.headers).to(haveStandardHeadersSet())
            }

            it("Should pass in correct form data with email containing plus character") {
                var stub = NetworkStub(path: .path(Router.passwordlessStart.path))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)
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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.formData?["phone_number"]).to(beNil())
                expect(data?.formData?["email"]) == self.testEmailContainingPlus
                expect(data?.formData?["client_id"]).to(equal(self.testClientID))
                expect(data?.formData?["connection"]).to(equal("email"))
                expect(data?.formData?["locale"]).to(equal(self.testLocale))
                expect(data?.headers).to(haveStandardHeadersSet())
            }

            it("Should handle network errors") {
                let expectedError = NSError(domain: "Network error", code: 0, userInfo: nil)
                var stub = NetworkStub(path: .path(Router.passwordlessStart.path))
                stub.returnError(error: expectedError)
                StubbedNetworkingProxy.addStub(stub)

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
                var stub = NetworkStub(path: .path(Router.passwordlessStart.path))
                stub.returnData(json: .fromFile("invalid-phone-number-error"))
                stub.returnResponse(status: 400)
                StubbedNetworkingProxy.addStub(stub)

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
                var stub = NetworkStub(path: .path(Router.passwordlessStart.path))
                stub.returnData(json: .fromFile("empty"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

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
                var stub = NetworkStub(path: .path(Router.passwordlessStart.path))
                stub.returnData(json: .fromFile("valid-passwordless"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)
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
                var stub = NetworkStub(path: .path(Router.validate.path))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)
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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.formData?["client_id"]) == self.testClientID
                expect(data?.formData?["identifier"]) == self.testNumber
                expect(data?.formData?["code"]) == self.testAuthCode
                expect(data?.formData?["passwordless_token"]) == String(describing: self.testPasswordlessToken)
                expect(data?.formData?["scope"]) == "openid"
                expect(data?.headers).to(haveStandardHeadersSet())
            }

            it("Should handle network errors") {
                let expectedError = NSError(domain: "Network error", code: 0, userInfo: nil)

                var stub = NetworkStub(path: .path(Router.validate.path))
                stub.returnError(error: expectedError)
                StubbedNetworkingProxy.addStub(stub)

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
                var stub = NetworkStub(path: .path(Router.validate.path))
                stub.returnData(json: .fromFile("invalid-authcode-no-access-token"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

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
                var stub = NetworkStub(path: .path(Router.validate.path))
                stub.returnData(json: .fromFile("valid-authcode"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)
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
                var stub = NetworkStub(path: .path(Router.validate.path))
                stub.returnData(json: .fromFile("invalid-authcode"))
                stub.returnResponse(status: 400)
                StubbedNetworkingProxy.addStub(stub)

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

        describe("request access token") {

            it("should error with invalid scope specified") {
                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("password-grant-invalid-scope"))
                stub.returnResponse(status: 400)
                StubbedNetworkingProxy.addStub(stub)

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.requestAccessToken(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret,
                        grantType: .password,
                        username: self.testEmail,
                        password: self.testPassword,
                        scope: ["whatever"]
                    ) { result in
                        expect(result).to(failWith(ClientError.invalidScope))
                        done()
                    }
                }
            }
        }

        describe("refresh") {
            it("Should pass in correct form data") {
                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)
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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.formData?["client_id"]).to(equal(self.testClientID))
                expect(data?.formData?["grant_type"]).to(equal("refresh_token"))
                expect(data?.formData?["refresh_token"]).to(equal(self.testRefreshToken))
                expect(data?.headers).to(haveStandardHeadersSet())
            }

            it("Should handle network errors") {
                let expectedError = NSError(domain: "Network error", code: 0, userInfo: nil)
                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnError(error: expectedError)
                StubbedNetworkingProxy.addStub(stub)

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
                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("valid-refresh"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

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
                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("invalid-refresh-no-access-token"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

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
                var stub = NetworkStub(path: .path(Router.passwordlessResend.path))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)
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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.formData?["client_id"]) == self.testClientID
                expect(data?.formData?["passwordless_token"]) == String(describing: self.testPasswordlessToken)
                expect(data?.formData?["locale"]) == self.testLocale
                expect(data?.headers).to(haveStandardHeadersSet())
            }

            it("Should handle network errors") {
                let expectedError = NSError(domain: "Network error", code: 0, userInfo: nil)
                var stub = NetworkStub(path: .path(Router.passwordlessResend.path))
                stub.returnError(error: expectedError)
                StubbedNetworkingProxy.addStub(stub)

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
                var stub = NetworkStub(path: .path(Router.passwordlessResend.path))
                stub.returnData(json: .fromFile("empty"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

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
                var stub = NetworkStub(path: .path(Router.passwordlessResend.path))
                stub.returnData(json: .fromFile("valid-passwordless"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

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
                let stub = NetworkStub(path: .path(Router.agreementsStatus(userID: self.testUserID).path))
                StubbedNetworkingProxy.addStub(stub)

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.fetchAgreementsAcceptanceStatus(
                        oauthToken: self.testOauthToken,
                        userID: self.testUserID
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.request?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(data?.url?.absoluteString).to(contain(self.testUserID))
                expect(data?.headers).to(haveStandardHeadersSet())
            }
        }

        describe("acceptAgreements") {
            it("should pass in correct data") {
                let stub = NetworkStub(path: .path(Router.acceptAgreements(userID: self.testUserID).path))
                StubbedNetworkingProxy.addStub(stub)
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.acceptAgreements(
                        oauthToken: self.testOauthToken,
                        userID: self.testUserID
                    ) { _ in
                        done()
                    }
                }
                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.request?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(data?.url?.absoluteString).to(contain(self.testUserID))
                expect(data?.headers).to(haveStandardHeadersSet())
            }
        }

        describe("fetchTerms") {
            it("should pass in correct data") {
                let stub = NetworkStub(path: .path(Router.terms.path))
                StubbedNetworkingProxy.addStub(stub)

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.fetchTerms(
                        clientID: self.testClientID
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                let query = URLComponents(url: data!.url!, resolvingAgainstBaseURL: false)
                let contains = query?.queryItems?.contains(where: { (item) -> Bool in
                    item.name == "client_id" && item.value == self.testClientID
                })
                expect(contains).to(be(true))
            }
        }

        describe("fetchClientAccessToken") {
            it("should pass in correct data") {
                let stub = NetworkStub(path: .path(Router.oauthToken.path))
                StubbedNetworkingProxy.addStub(stub)
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.fetchClientAccessToken(
                        clientID: self.testClientID,
                        clientSecret: self.testClientSecret
                    ) { _ in
                        done()
                    }
                }
                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.formData?["client_id"]).to(equal(self.testClientID))
                expect(data?.formData?["client_secret"]).to(equal("clientSecret"))
                expect(data?.formData?["grant_type"]).to(equal("client_credentials"))
                expect(data?.headers).to(haveStandardHeadersSet())
            }
        }

        describe("fetchIdentifierStatus") {
            it("should pass in correct data on phone") {
                let stub = NetworkStub(path: .path(Router.identifierStatus(connection: .sms, identifierInBase64: "base64").path))
                StubbedNetworkingProxy.addStub(stub)
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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.request?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(data?.url?.absoluteString).to(contain("phone"))
                expect(data?.headers).to(haveStandardHeadersSet())
            }

            it("should pass in correct data") {
                let stub = NetworkStub(path: .path(Router.identifierStatus(connection: .email, identifierInBase64: "base64").path))
                StubbedNetworkingProxy.addStub(stub)
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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.request?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(data?.url?.absoluteString).to(contain("email"))
                expect(data?.headers).to(haveStandardHeadersSet())
            }
        }

        describe("fetchUserProfile") {
            it("should pass in correct data") {
                let stub = NetworkStub(path: .path(Router.profile(userID: self.testUserID).path))
                StubbedNetworkingProxy.addStub(stub)
                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.fetchUserProfile(
                        userID: self.testUserID,
                        oauthToken: self.testOauthToken
                    ) { _ in
                        done()
                    }
                }

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.request?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(data?.url?.absoluteString).to(contain(self.testUserID))
                expect(data?.headers).to(haveStandardHeadersSet())
            }
        }

        describe("signup") {
            it("should pass in correct data") {
                let stub = NetworkStub(path: .path(Router.signup.path))
                StubbedNetworkingProxy.addStub(stub)
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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.request?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(data?.formData?["email"]).to(equal(self.testEmail))
                expect(data?.formData?["password"]).to(equal("password"))
                expect(data?.headers).to(haveStandardHeadersSet())
            }

            it("Should get the usermodel back") {
                var stub = NetworkStub(path: .path(Router.signup.path))
                stub.returnData(json: .fromFile("signup-valid"))
                stub.returnResponse(status: 201)
                StubbedNetworkingProxy.addStub(stub)
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
                let stub = NetworkStub(path: .path(Router.exchangeToken.path))
                StubbedNetworkingProxy.addStub(stub)
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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.request?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(data?.formData?["clientId"]).to(equal(self.testClientID))
                expect(data?.formData?["type"]).to(equal(TokenExchangeType.code.rawValue))
                expect(data?.headers).to(haveStandardHeadersSet())
            }

            it("should pass in correct data session") {
                let stub = NetworkStub(path: .path(Router.exchangeToken.path))
                StubbedNetworkingProxy.addStub(stub)
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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.request?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(data?.formData?["clientId"]).to(equal(self.testClientID))
                expect(data?.formData?["type"]).to(equal(TokenExchangeType.session.rawValue))
                expect(data?.headers).to(haveStandardHeadersSet())
            }
        }

        describe("updateUserProfile") {
            it("should pass in correct data") {
                let stub = NetworkStub(path: .path(Router.updateProfile(userID: self.testUserID).path))
                StubbedNetworkingProxy.addStub(stub)
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

                expect(Networking.testingProxy.requests.count) == 1
                let data = Networking.testingProxy.requests.data.first
                expect(data?.request?.allHTTPHeaderFields?["Authorization"]).to(contain(self.testOauthToken))
                expect(data?.formData?["name"]).to(contain("new name"))
                expect(data?.url?.absoluteString).to(contain(self.testUserID))
                expect(data?.headers).to(haveStandardHeadersSet())
            }

            it("should get the new profile returned") {
                var stub = NetworkStub(path: .path(Router.updateProfile(userID: self.testUserID).path))
                stub.returnData(json: .fromFile("user-profile-valid"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

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

        describe("fetch product") {

            it("Should handle no access to product") {
                let productID = "123"
                var stub = NetworkStub(path: .path(Router.product(userID: self.testUserID, productID: productID).path))
                stub.returnData(json: .fromFile("product-no-access"))
                stub.returnResponse(status: 404)
                StubbedNetworkingProxy.addStub(stub)

                let api = IdentityAPI(basePath: self.testBasePath)

                waitUntil { done in
                    api.fetchUserProduct(
                        oauthToken: self.testOauthToken,
                        userID: self.testUserID,
                        productID: productID
                    ) { result in
                        expect(result).to(failWith(ClientError.noAccess))
                        done()
                    }
                }
            }
        }
    }
}
