//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class IdentityAPI {
    let basePath: URL

    init(basePath: URL) {
        self.basePath = basePath
    }

    func fetchClient(oauthToken: String, clientID: String, completion: @escaping ((Result<Client, ClientError>) -> Void)) {
        let task = request(
            router: .client(clientID: clientID),
            headers: [.authorization: oauthToken.bearer],
            completion: completion
        )
        task?.resume()
    }

    func fetchAgreementsAcceptanceStatus(oauthToken: String,
                                         userID: String,
                                         completion: @escaping ((Result<Agreements, ClientError>) -> Void)) {
        let task = request(router: .agreementsStatus(userID: userID),
                           headers: [.authorization: oauthToken.bearer],
                           completion: completion)
        task?.resume()
    }

    func acceptAgreements(oauthToken: String,
                          userID: String,
                          completion: @escaping ((Result<EmptyResponse, ClientError>) -> Void)) {
        let task = request(router: .acceptAgreements(userID: userID),
                           headers: [.authorization: oauthToken.bearer],
                           completion: completion)
        task?.resume()
    }

    func fetchClientAccessToken(clientID: String,
                                clientSecret: String,
                                completion: @escaping ((Result<TokenData, ClientError>) -> Void)) {
        self.requestAccessToken(clientID: clientID, clientSecret: clientSecret, grantType: .clientCredentials, completion: completion)
    }

    func fetchIdentifierStatus(oauthToken: String,
                               identifierInBase64: String,
                               connection: Connection,
                               completion: @escaping ((Result<IdentifierStatus, ClientError>) -> Void)) {
        let task = request(router: .identifierStatus(connection: connection,
                                                     identifierInBase64: identifierInBase64),
                           headers: [.authorization: oauthToken.bearer],
                           completion: completion)
        task?.resume()
    }

    func fetchUserProfile(userID: String,
                          oauthToken: String,
                          completion: @escaping ((Result<UserProfile, ClientError>) -> Void)) {
        let task = request(router: .profile(userID: userID),
                           headers: [.authorization: oauthToken.bearer],
                           completion: completion)
        task?.resume()
    }

    func fetchUserProduct(oauthToken: String,
                          userID: String,
                          productID: String,
                          completion: @escaping ((Result<UserProduct, ClientError>) -> Void)) {
        let task = request(router: .product(userID: userID, productID: productID),
                           headers: [.authorization: oauthToken.bearer],
                           completion: completion)
        task?.resume()
    }

    func logout(oauthToken: String,
                completion: @escaping ((Result<EmptyResponse, ClientError>) -> Void)) {
        let task = request(router: .logout,
                           headers: [.authorization: oauthToken.bearer],
                           completion: completion)
        task?.resume()
    }

    func requestAccessToken(clientID: String,
                            clientSecret: String,
                            grantType: RequestAccessTokenType,
                            refreshToken: String? = nil,
                            username: String? = nil,
                            password: String? = nil,
                            code: String? = nil,
                            redirectURI: String? = nil,
                            scope: [String]? = nil,
                            completion: @escaping ((Result<TokenData, ClientError>) -> Void)) {
        let formData: [String: String?] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "grant_type": grantType.rawValue,
            "refresh_token": refreshToken,
            "username": username,
            "password": password,
            "code": code,
            "redirect_uri": redirectURI,
            "scope": scope?.trimmed().joined(separator: " "),
        ]

        let task = request(router: .oauthToken, formData: formData, completion: completion)
        task?.resume()
    }

    func startPasswordless(
        clientID: String,
        clientSecret: String,
        locale: String,
        identifier: String,
        connection: Connection,
        completion: @escaping ((Result<PasswordlessToken, ClientError>) -> Void)
    ) {
        var formData = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "connection": connection.rawValue,
            "locale": locale,
        ]

        switch connection {
        case .sms:
            formData["phone_number"] = identifier
        case .email:
            formData["email"] = identifier
        }

        let task = request(router: .passwordlessStart, formData: formData, completion: completion)

        task?.resume()
    }

    func resendCode(clientID: String,
                    clientSecret: String,
                    passwordlessToken: PasswordlessToken,
                    locale: String,
                    completion: @escaping ((Result<PasswordlessToken, ClientError>) -> Void)) {
        let formData: [String: String] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "passwordless_token": String(describing: passwordlessToken),
            "locale": locale,
        ]

        let task = request(router: .passwordlessResend, formData: formData, completion: completion)
        task?.resume()
    }

    func signup(
        oauthToken: String,
        email: String,
        password: String? = nil,
        redirectURI: String? = nil,
        profile: UserProfile? = nil,
        acceptTerms: Bool? = nil,
        completion: @escaping ((Result<UserModel, ClientError>) -> Void)
    ) {
        var formData = [
            "email": email,
            "password": password,
            "redirectUri": redirectURI,
        ]

        if let profile = profile {
            formData = formData.mergedByOverwriting(with: profile.formData(withMappings: [
                .givenName: "given_name",
                .familyName: "family_name",
            ]))
        }

        if let acceptTerms = acceptTerms {
            formData["acceptTerms"] = acceptTerms ? String(1) : String(0)
        }

        let task = request(router: .signup, formData: formData, headers: [.authorization: oauthToken.bearer], completion: completion)
        task?.resume()
    }

    func tokenExchange(oauthToken: String,
                       clientID: String,
                       type: TokenExchangeType,
                       redirectURI: String? = nil,
                       completion: @escaping ((Result<TokenExchange, ClientError>) -> Void)) {
        let formData = [
            "clientId": clientID,
            "type": type.rawValue,
            "redirectUri": redirectURI,
        ]

        let task = request(router: .exchangeToken, formData: formData, headers: [.authorization: oauthToken.bearer], completion: completion)
        task?.resume()
    }

    func updateUserProfile(
        userID: String,
        oauthToken: String,
        profile: UserProfile,
        completion: @escaping ((Result<UserProfile, ClientError>) -> Void)
    ) {
        let formData = profile.formData()
        let task = request(router: .updateProfile(userID: userID), formData: formData, headers: [.authorization: oauthToken.bearer], completion: completion)
        task?.resume()
    }

    func validateCode(clientID: String,
                      clientSecret: String,
                      identifier: String,
                      connection: Connection,
                      code: String,
                      passwordlessToken: PasswordlessToken,
                      scope: [String] = [],
                      completion: @escaping ((Result<TokenData, ClientError>) -> Void)) {
        let formData = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "identifier": identifier,
            "connection": connection.rawValue,
            "code": code,
            "grant_type": "passwordless",
            "passwordless_token": String(describing: passwordlessToken),
            "scope": scope.trimmed().joined(separator: " "),
        ]

        let task = request(router: Router.validate, formData: formData, completion: completion)
        task?.resume()
    }

    func fetchTerms(clientID: String, completion: @escaping TermsResultCallback) {
        let task = request(router: .terms, parameters: ["client_id": clientID], completion: completion)
        task?.resume()
    }

    func fetchRequiredFields(oauthToken: String, userID: String, completion: @escaping (Result<RequiredFields, ClientError>) -> Void) {
        let task = request(router: .requiredFields(userID: userID), headers: [.authorization: oauthToken.bearer], completion: completion)
        task?.resume()
    }

    private static func triviallyParseSpidError(_ error: Error, path: String) -> ClientError? {
        /*
         Current known spid error formats (There's also a "code" key there somewhere, sometimes, but we just get that from URLResponse):
         1.
           {
             "error": "string",
             "type": "string"
           }

         2.
           {
             "error" {
               "type": "string",
               "description": "string"
             }
           }

         3.
           {
             "error" {
               "type": "string",
               "description": {
                 "key1": "message",
                 "key2": "message",
                 ...,
                 "key_1_billion_who_knows": "message"
               }
             }
           }
         */

        enum SPIDError: Error, CustomStringConvertible {
            enum Description {
                case string(String)
                case object(JSONObject)
            }
            case string(value: String, type: String, code: Int)
            case object(type: String, description: Description, code: Int)
            var description: String {
                switch self {
                case let .string(string, type, statusCode):
                    return "SPIDError: string: \(string), type: \(type), code: \(statusCode)"
                case let .object(type, description, statusCode):
                    return "SPIDError: object: { type: \(type), description: \(description), code: \(statusCode) }"
                }
            }
        }

        guard case let NetworkingError.unexpectedStatus(statusCode, data) = error, let json = try? data.jsonObject() else {
            return nil
        }

        guard let spidError = { () -> SPIDError? in
            if let string = try? json.string(for: "error") {
                if let type = try? json.string(for: "type") {
                    return .string(value: string, type: type, code: statusCode)
                }
                return .string(value: string, type: "", code: statusCode)
            }

            if let object = try? json.jsonObject(for: "error"), let type = try? object.string(for: "type") {
                if let description = try? object.string(for: "description") {
                    return .object(type: type, description: .string(description), code: statusCode)
                }

                if let description = try? object.jsonObject(for: "description") {
                    return .object(type: type, description: .object(description), code: statusCode)
                }
            }

            return nil
        }() else {
            return nil
        }

        switch spidError {
        case .string("invalid_user_credentials", "OAuthException", 400):
            return .invalidUserCredentials(message: nil)
        case .string("invalid_client_credentials", "OAuthException", 400):
            return .invalidClientCredentials
        case .string("unverified_user", "OAuthException", 400):
            return .unverifiedEmail
        case .string("invalid_scope", "OAuthException", _):
            return .invalidScope
        case let .object("invalid_request", .string(string), _) where string.contains("*phone_number*"):
            return .invalidPhoneNumber
        case let .object("invalid_request", .string(string), _) where string.contains("*email*"):
            return .invalidEmail
        case let .object("invalid_request", .string(string), _) where string.contains("*client_id*"):
            return .invalidClientCredentials
        case let .object("invalid_request", .string(string), 400) where string.contains("passwordless") && Router.passwordlessResend.matches(path: path):
            return .unableToResend
        case .object("invalid_grant", _, 400), .string("invalid_grant", _, 400):
            return .invalidCode
        case .object("too_many_requests", _, 429):
            return .tooManyRequests
        case let .object("ApiException", .string(string), 400) where string.contains("valid phone number"):
            return .invalidPhoneNumber
        case let .object("ApiException", .string(string), 302):
            return .alreadyRegistered(message: string)
        case let .object("ApiException", .object(object), code):
            if let existsMessage = object["exists"] as? String, code == 302 {
                if Router.signup.matches(path: path) {
                    return .unverifiedEmail
                } else {
                    return .alreadyRegistered(message: existsMessage)
                }
            }
            if let passwordMessage = object["password"] as? String {
                return .invalidUserCredentials(message: passwordMessage)
            }
            fallthrough
        default:
            let data = String(describing: spidError).data(using: .utf8) ?? data
            return ClientError(NetworkingError.unexpectedStatus(status: statusCode, data: data))
        }
    }

    private func request<T: JSONParsable>(
        router: Router,
        formData: [String: String?] = [:],
        headers: [Networking.Header: String] = [:],
        parameters: [String: String] = [:],
        completion: @escaping ((Result<T, ClientError>) -> Void)
    ) -> URLSessionDataTask? {
        guard let escapedPath = router.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completion(.failure(.unexpected(NetworkingError.malformedURL)))
            return nil
        }
        let urlString = basePath.appendingPathComponent(escapedPath).absoluteString
        let urlComponents = NSURLComponents(string: urlString)
        let queryItems = parameters.map { URLQueryItem(name: $0.0, value: $0.1) }
        urlComponents?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = urlComponents?.url else {
            completion(.failure(.unexpected(NetworkingError.malformedURL)))
            return nil
        }

        let nonNilFormData = formData.compactedValues()

        log(from: self, url)
        return Networking.send(to: url, using: router.method, headers: headers, formData: nonNilFormData, completion: { data, response, error in
            do {
                let data = try Networking.Utils.ensureResponse(data, response, error)(Array(200...299))
                let json = try data.jsonObject()

                let object = try T(from: json)
                completion(.success(object))
            } catch {
                guard let clientError = type(of: self).triviallyParseSpidError(error, path: url.path) else {
                    completion(.failure(ClientError(NetworkingError(error))))
                    return
                }
                completion(.failure(clientError))
            }
        })
    }
}

enum Connection: String {
    case email
    case sms
}

enum TokenExchangeType: String {
    case code
    case session
}

enum RequestAccessTokenType: String {
    case password
    case refreshToken = "refresh_token"
    case authorizationCode = "authorization_code"
    case clientCredentials = "client_credentials"
}
