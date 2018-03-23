//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class IdentifierViewModel {
    let loginMethod: LoginMethod
    let localizedTeaserText: String?
    let localizationBundle: Bundle

    var helpURL: URL {
        guard let url = URL(string: "https://www.schibstedpayment.com/hc/sv/#faq") else {
            preconditionFailure("Failed to make help me URL")
        }
        return url
    }

    init(loginMethod: LoginMethod, localizedTeaserText: String?, localizationBundle: Bundle) {
        self.loginMethod = loginMethod
        self.localizedTeaserText = localizedTeaserText
        self.localizationBundle = localizationBundle
    }
}

extension IdentifierViewModel {
    var privacyText: String {
        switch self.loginMethod.identifierType {
        case .email:
            return "IdentifierScreenString.privacyText.email".localized(from: self.localizationBundle)
        case .phone:
            return "IdentifierScreenString.privacyText.phone".localized(from: self.localizationBundle)
        }
    }

    var proceed: String {
        return "IdentifierScreenString.proceed".localized(from: self.localizationBundle)
    }

    var inputTitle: String {
        switch self.loginMethod.methodType {
        case .email:
            return "IdentifierScreenString.inputTitle.email".localized(from: self.localizationBundle)
        case .phone:
            return "IdentifierScreenString.inputTitle.phone".localized(from: self.localizationBundle)
        case .password:
            return "IdentifierScreenString.inputTitle.password".localized(from: self.localizationBundle)
        }
    }

    var title: String {
        switch self.loginMethod.identifierType {
        case .email:
            return "IdentifierScreenString.title.email".localized(from: self.localizationBundle)
        case .phone:
            return "IdentifierScreenString.title.sms".localized(from: self.localizationBundle)
        }
    }

    var done: String {
        return "GlobalString.done".localized(from: self.localizationBundle)
    }

    var invalidEmail: String {
        return ClientError.invalidEmail.localized(from: self.localizationBundle)
    }

    var invalidPhoneNumber: String {
        return ClientError.invalidPhoneNumber.localized(from: self.localizationBundle)
    }

    var needHelp: String {
        return "IdentifierScreenString.needHelp".localized(from: self.localizationBundle)
    }
}
