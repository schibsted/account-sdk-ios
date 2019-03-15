//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class PasswordViewModel {
    let identifier: Identifier
    let loginFlowVariant: LoginMethod.FlowVariant
    let localizationBundle: Bundle

    init(identifier: Identifier, loginFlowVariant: LoginMethod.FlowVariant, localizationBundle: Bundle) {
        self.identifier = identifier
        self.loginFlowVariant = loginFlowVariant
        self.localizationBundle = localizationBundle
    }
}

extension PasswordViewModel {
    var proceed: String {
        return "PasswordScreenString.proceed".localized(from: self.localizationBundle)
    }

    var inputTitle: String {
        return "PasswordScreenString.inputTitle".localized(from: self.localizationBundle)
    }

    var titleSignin: String {
        return "PasswordScreenString.title.signin".localized(from: self.localizationBundle)
    }

    var titleSignup: String {
        return "PasswordScreenString.title.signup".localized(from: self.localizationBundle)
    }

    var invalidPassword: String {
        return "PasswordScreenString.invalidPassword".localized(from: self.localizationBundle)
    }

    var passwordTooShort: String {
        return "PasswordScreenString.invalidPassword".localized(from: self.localizationBundle)
    }

    var done: String {
        return "GlobalString.done".localized(from: self.localizationBundle)
    }

    var change: String {
        return "PasswordScreenString.change".localized(from: self.localizationBundle)
    }

    var cancel: String {
        return "PasswordScreenString.cancel".localized(from: self.localizationBundle)
    }

    var info: String {
        return "PasswordScreenString.info".localized(from: self.localizationBundle)
    }

    var ageLimit: String {
        return "PasswordScreenString.ageLimit".localized(from: self.localizationBundle)
    }

    var forgotPassword: String {
        return "PasswordScreenString.forgotPassword".localized(from: self.localizationBundle)
    }

    var persistentLogin: String {
        return "PasswordScreenString.persistentLogin".localized(from: self.localizationBundle)
    }

    var whatsThis: String {
        return "PasswordScreenString.whatsThis".localized(from: self.localizationBundle)
    }

    var rememberMe: String {
        return "InfoString.rememberMe".localized(from: self.localizationBundle)
    }

    var creatingNewAccountNotice: String {
        return "PasswordScreenString.creatingNewAccountNotice".localized(from: self.localizationBundle)
    }

    var createAccount: String {
        return "PasswordScreenString.createAccount".localized(from: self.localizationBundle)
    }
    var biometricsPrompt: String {
        return "PasswordScreenString.biometricsPrompt".localized(from: self.localizationBundle)
    }
    var biometricsOnboardingTitle: String {
        return "PasswordScreenString.biometricsOnboarding.title".localized(from: self.localizationBundle)
    }
    var biometricsOnboardingMessage: String {
        return "PasswordScreenString.biometricsOnboarding.message".localized(from: self.localizationBundle)
    }
    var biometricsOnboardingAccept: String {
        return "PasswordScreenString.biometricsOnboarding.accept".localized(from: self.localizationBundle)
    }
    var biometricsOnboardingRefuse: String {
        return "PasswordScreenString.biometricsOnboarding.refuse".localized(from: self.localizationBundle)
    }
}
