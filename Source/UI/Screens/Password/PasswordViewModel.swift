//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
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
        return "PasswordScreenString.proceed".localized(from: localizationBundle)
    }

    var inputTitle: String {
        return "PasswordScreenString.inputTitle".localized(from: localizationBundle)
    }

    var titleSignin: String {
        return "PasswordScreenString.title.signin".localized(from: localizationBundle)
    }

    var titleSignup: String {
        return "PasswordScreenString.title.signup".localized(from: localizationBundle)
    }

    var invalidPassword: String {
        return "PasswordScreenString.invalidPassword".localized(from: localizationBundle)
    }

    var passwordTooShort: String {
        return "PasswordScreenString.invalidPassword".localized(from: localizationBundle)
    }

    var done: String {
        return "GlobalString.done".localized(from: localizationBundle)
    }

    var change: String {
        return "PasswordScreenString.change".localized(from: localizationBundle)
    }

    var cancel: String {
        return "PasswordScreenString.cancel".localized(from: localizationBundle)
    }

    var info: String {
        return "PasswordScreenString.info".localized(from: localizationBundle)
    }

    var ageLimit: String {
        return "PasswordScreenString.ageLimit".localized(from: localizationBundle)
    }

    var forgotPassword: String {
        return "PasswordScreenString.forgotPassword".localized(from: localizationBundle)
    }

    var persistentLogin: String {
        return "PasswordScreenString.persistentLogin".localized(from: localizationBundle)
    }

    var whatsThis: String {
        return "PasswordScreenString.whatsThis".localized(from: localizationBundle)
    }

    var rememberMe: String {
        return "InfoString.rememberMe".localized(from: localizationBundle)
    }

    var creatingNewAccountNotice: String {
        return "PasswordScreenString.creatingNewAccountNotice".localized(from: localizationBundle)
    }

    var createAccount: String {
        return "PasswordScreenString.createAccount".localized(from: localizationBundle)
    }
    var biometricsPrompt: String {
        return "PasswordScreenString.biometricsPrompt".localized(from: localizationBundle)
    }
    var touchIdOnboardingTitle: String {
        return "PasswordScreenString.touchIdOnboarding.title".localized(from: localizationBundle)
    }
    var touchIdOnboardingMessage: String {
        return "PasswordScreenString.touchIdOnboarding.message".localized(from: localizationBundle)
    }
    var touchIdOnboardingAccept: String {
        return "PasswordScreenString.touchIdOnboarding.accept".localized(from: localizationBundle)
    }
    var touchIdOnboardingRefuse: String {
        return "PasswordScreenString.touchIdOnboarding.refuse".localized(from: localizationBundle)
    }
}
