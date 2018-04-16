//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

extension ClientError {
    func localized(from localizationBundle: Bundle) -> String {
        switch self {
        case .invalidPhoneNumber:
            return "ErrorString.invalidPhoneNumber".localized(from: localizationBundle)
        case .invalidCode:
            return "ErrorString.invalidCode".localized(from: localizationBundle)
        case .invalidEmail:
            return "ErrorString.invalidEmail".localized(from: localizationBundle)
        case let .networkingError(error):
            let code = (error as NSError).code
            switch code {
            case NSURLErrorTimedOut:
                return "ErrorString.connectionTimeout".localized(from: localizationBundle)
            case NSURLErrorNotConnectedToInternet:
                return "ErrorString.noInternetConnection".localized(from: localizationBundle)
            default:
                return "ErrorString.networkingError".localized(from: localizationBundle)
            }
        case .unexpected:
            return "ErrorString.unexpected".localized(from: localizationBundle)
        case .tooManyRequests:
            return "ErrorString.tooManyRequests".localized(from: localizationBundle)
        case .unableToResend:
            return "ErrorString.unableToResend".localized(from: localizationBundle)
        case .invalidUserCredentials:
            return "PasswordScreenString.invalidPassword".localized(from: localizationBundle)
        case .invalidClientCredentials, .invalidUser, .unexpectedIdentifier, .unverifiedEmail, .alreadyRegistered, .userRefreshFailed, .invalidScope:
            //
            // These do not have translations deliberately because they don't make sense to a user when trying to visually login, or
            // they are handled in some other way in the UI flows:
            //
            // Extra notes:
            //  * unverifiedEmail has no translation because it's not an error in the UI flow, it leads to a "check your inbox" screen
            //  * alreadyRegistered should never happen because it happens during signup, and we should check identifier status before getting there
            //
            return self.description
        case .requiredField, .agreements:
            // These are just here because of tracking right now. See GH issues 601, 603
            return self.description
        }
    }
}
