//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 The errors that can occur from client facing APIs
 */
public enum ClientError: Error {
    /// A networking error occured between the client and the identity server or
    /// the client and the server that was being requested
    case networkingError(Error)

    /// Occurs when `IdentityManager.validate(oneTimeCode:)` is given an incorrect code
    case invalidCode

    /// Occurs when you request a scope that you do not have access to
    case invalidScope

    /// Occurs when `IdentityManager.resendCode` cannot resend the code
    case unableToResend

    /// Occurs when 'IdentityManager.sendCode(to:completion:)` is given an invalid phone number
    case invalidPhoneNumber

    /// Occurs when a malformed e-mail is provided to an IdentityManager API call.
    case invalidEmail

    /// Occurs when a valid user object is needed but the user object is not valid
    case invalidUser

    /// Occurs when an identifier is invalid
    case unexpectedIdentifier(actual: Identifier, expected: String)

    /// Occurs when user credentials are invalid using email/password APIs
    case invalidUserCredentials(message: String?)

    /// Occurs when client credentials are invalid
    case invalidClientCredentials

    /// Occurs when password is shorter than 8 characters
    case passwordTooShort

    /// Occurs when you try to login with an unverified email
    case unverifiedEmail

    /// Occurs when you try to signup with an identifier that's already registered
    case alreadyRegistered(message: String)

    /// Occurs when there's a user refresh failure (i.e. an authenticated request failure)
    case userRefreshFailed(Error)

    /// Occurs when the limit of requests per minute is exceeded
    case tooManyRequests

    /// Could be anything. The world is its oyster.
    case unexpected(Error)

    /// Will happen when the user is missing some agreements
    case agreements

    /// Occurs when an invalid payload data is send to device api
    case invalidDevicePayloadData

    /// Will happen if a required field is failing validation
    case requiredField([String])

    /// Occurs when user does not have access to a requested resource (e.g. a product)
    case noAccess
}

extension ClientError {
    /**
     When the SDK returns custom NSError objects. The domain is set to this.
     */
    public static let domain = "ClientError"
    /**
     This is the error code inside the NSError object that is returned from `URLSession.dataTask(with:completion:)` in the case
     that the number of refresh retries has been exceeded
     */
    public static let RefreshRetryExceededCode = 2
}

extension ClientError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .networkingError(error):
            return "There was an error making the network request: \(error)"
        case .invalidCode:
            return "Ooops, please check your code again"
        case .unableToResend:
            return "Could not resend code"
        case .invalidPhoneNumber:
            return "Sorry, that number doesn't look right"
        case .invalidEmail:
            return "Sorry, that e-mail doesn't look right"
        case let .invalidUserCredentials(reason):
            if let reason = reason {
                return "Invalid user credentials: \(reason)"
            }
            return "Invalid user credentials"
        case .invalidClientCredentials:
            return "Invalid client credentials"
        case .invalidUser:
            return "User invalid"
        case let .unexpected(error):
            return "Unexpected error: \(error)"
        case .unverifiedEmail:
            return "The e-mail was not verified"
        case let .alreadyRegistered(message):
            return "Already registered: \(message)"
        case let .unexpectedIdentifier(identifier, expected):
            return "Identifier \"\(identifier)\" invalid - expected \(expected)"
        case let .userRefreshFailed(error):
            return "Failed to refresh: \(error)"
        case .tooManyRequests:
            return "Too many requests"
        case .agreements:
            return "Missing accept in agreements"
        case let .requiredField(fields):
            return "Required fields are failing validation: \(fields)"
        case .invalidScope:
            return "One or more specified scopes are invalid"
        case .noAccess:
            return "Access is not allowed"
        case .passwordTooShort:
            return "Your password should have at least 8 characters."
        case .invalidDevicePayloadData:
            return "Invalid device payload data"
        }
    }
}

protocol ClientErrorConvertible {
    var clientError: ClientError { get }
}

extension ClientError: ClientErrorConvertible {
    var clientError: ClientError {
        return self
    }

    init(_ error: Error) {
        if let error = error as? ClientErrorConvertible {
            self = error.clientError
        } else {
            self = .unexpected(error)
        }
    }
}

extension JSONError: ClientErrorConvertible {
    var clientError: ClientError {
        return .unexpected(self)
    }
}

extension JWTHelperError: ClientErrorConvertible {
    var clientError: ClientError {
        return .unexpected(self)
    }
}

extension NetworkingError: ClientErrorConvertible {
    var clientError: ClientError {
        switch self {
        case let .requestError(error):
            return .networkingError(error)
        case .unexpectedStatus:
            return .networkingError(self)
        case let .unexpected(error):
            return .unexpected(error)
        default:
            return .unexpected(self)
        }
    }
}
