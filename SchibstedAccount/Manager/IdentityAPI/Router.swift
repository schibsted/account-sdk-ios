//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

enum Router {
    case signup
    case identifierStatus(connection: Connection, identifierInBase64: String)
    case oauthToken
    case passwordlessStart
    case passwordlessResend
    case validate
    case exchangeToken
    case agreementsStatus(userID: String)
    case acceptAgreements(userID: String)
    case profile(userID: String)
    case updateProfile(userID: String)
    case terms
    case logout
    case requiredFields(userID: String)
    case client(clientID: String)
    case product(userID: String, productID: String)

    var method: Networking.HTTPMethod {
        switch self {
        case .signup:
            return .POST
        case .identifierStatus:
            return .GET
        case .oauthToken:
            return .POST
        case .passwordlessStart:
            return .POST
        case .passwordlessResend:
            return .POST
        case .validate:
            return .POST
        case .exchangeToken:
            return .POST
        case .agreementsStatus:
            return .GET
        case .acceptAgreements:
            return .POST
        case .profile:
            return .GET
        case .updateProfile:
            return .POST
        case .terms:
            return .GET
        case .logout:
            return .GET
        case .requiredFields:
            return .GET
        case .client:
            return .GET
        case .product:
            return .GET
        }
    }

    func matches(path: String) -> Bool {
        switch self {
        case .signup, .passwordlessResend:
            return path == self.path
        default:
            return false
        }
    }

    var path: String {
        switch self {
        case let .client(clientID):
            return "/api/2/client/\(clientID)"
        case .signup:
            return "/api/2/signup"
        case let .identifierStatus(connection, identifierInBase64):
            let type: String
            switch connection {
            case .sms: type = "phone"
            case .email: type = "email"
            }
            return "/api/2/\(type)/\(identifierInBase64)/status"
        case .oauthToken:
            return "/oauth/token"
        case .passwordlessStart:
            return "/passwordless/start"
        case .passwordlessResend:
            return "/passwordless/resend"
        case .validate:
            return "/oauth/ro"
        case .exchangeToken:
            return "/api/2/oauth/exchange"
        case let .agreementsStatus(userID):
            return "/api/2/user/\(userID)/agreements"
        case let .acceptAgreements(userID):
            return "/api/2/user/\(userID)/agreements/accept"
        case let .profile(userID):
            return "/api/2/user/\(userID)"
        case let .updateProfile(userID):
            return "/api/2/user/\(userID)"
        case .terms:
            return "/api/2/terms"
        case .logout:
            return "/api/2/logout"
        case let .requiredFields(userID):
            return "/api/2/user/\(userID)/required_fields"
        case let .product(userID, productID):
            return "/api/2/user/\(userID)/product/\(productID)"
        }
    }
}
