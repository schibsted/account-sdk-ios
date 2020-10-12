//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//
import Foundation

class VerifyViewModel {
    static let numberOfCodeDigits = 6

    let identifier: Identifier
    let localizationBundle: Bundle

    init(identifier: Identifier, localizationBundle: Bundle) {
        self.identifier = identifier
        self.localizationBundle = localizationBundle
    }
}

extension VerifyViewModel {
    var subtext: String {
        return "VerifyScreenString.subtext".localized(from: localizationBundle, identifier.normalizedString)
    }

    var inputTitle: String {
        return "VerifyScreenString.inputTitle".localized(from: localizationBundle)
    }

    var resend: String {
        return "VerifyScreenString.resend".localized(from: localizationBundle)
    }

    var change: String {
        return "VerifyScreenString.change".localized(from: localizationBundle)
    }

    var proceed: String {
        return "VerifyScreenString.proceed".localized(from: localizationBundle)
    }

    var done: String {
        return "GlobalString.done".localized(from: localizationBundle)
    }

    var title: String {
        return "VerifyScreenString.title".localized(from: localizationBundle)
    }

    var invalidCode: String {
        return ClientError.invalidCode.localized(from: localizationBundle)
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
}
