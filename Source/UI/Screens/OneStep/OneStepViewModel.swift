//
//  OneStepViewModel.swift
//  SchibstedAccount
//

import Foundation

class OneStepViewModel {
    let localizedTeaserText: String?
    let localizationBundle: Bundle

    init(
        localizedTeaserText: String?,
        localizationBundle: Bundle
    ) {
        self.localizedTeaserText = localizedTeaserText
        self.localizationBundle = localizationBundle
    }
}

extension OneStepViewModel {
    var invalidPassword: String {
        return "OneStepLoginScreen.invalidPassword".localized(from: self.localizationBundle)
    }

    var proceed: String {
        return "OneStepLoginScreen.proceed".localized(from: self.localizationBundle)
    }

    var skip: String {
        return "OneStepLoginScreen.skip".localized(from: self.localizationBundle)
    }

    var whatsThis: String {
        return "OneStepLoginScreen.whatsThis".localized(from: self.localizationBundle)
    }

    var persistentLogin: String {
        return "OneStepLoginScreen.persistentLogin".localized(from: self.localizationBundle)
    }

    var emailInputTitle: String {
        return "OneStepLoginScreen.inputTitle.email".localized(from: self.localizationBundle)
    }

    var passwordInputTitle: String {
        return "OneStepLoginScreen.inputTitle.password".localized(from: self.localizationBundle)
    }

    var title: String {
        return "OneStepLoginScreen.title".localized(from: self.localizationBundle)
    }
}
