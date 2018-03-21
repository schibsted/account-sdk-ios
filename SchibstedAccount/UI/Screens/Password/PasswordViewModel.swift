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

    var forgotPassword: String {
        return "PasswordScreenString.forgotPassword".localized(from: self.localizationBundle)
    }

    var persistentLogin: String {
        return "PasswordScreenString.persistentLogin".localized(from: self.localizationBundle)
    }
}
