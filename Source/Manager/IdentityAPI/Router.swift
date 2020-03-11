//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
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
    case assets(userID: String)
    case profile(userID: String)
    case updateProfile(userID: String)
    case terms
    case requiredFields(userID: String)
    case client(clientID: String)
    case product(userID: String, productID: String)
    case devices

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
        case .assets:
            return .GET
        case .profile:
            return .GET
        case .updateProfile:
            return .POST
        case .terms:
            return .GET
        case .requiredFields:
            return .GET
        case .client:
            return .GET
        case .product:
            return .GET
        case .devices:
            return .POST
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
        case let .assets(userID):
            return "/api/2/user/\(userID)/assets"
        case let .profile(userID):
            return "/api/2/user/\(userID)"
        case let .updateProfile(userID):
            return "/api/2/user/\(userID)"
        case .terms:
            return "/api/2/terms"
        case let .requiredFields(userID):
            return "/api/2/user/\(userID)/required_fields"
        case let .product(userID, productID):
            return "/api/2/user/\(userID)/product/\(productID)"
        case .devices:
            return "/api/2/devices"
        }
    }
}
