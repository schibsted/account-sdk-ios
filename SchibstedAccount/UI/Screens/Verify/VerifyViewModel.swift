//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

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
        return "VerifyScreenString.subtext".localized(from: self.localizationBundle, self.identifier.normalizedString)
    }

    var inputTitle: String {
        return "VerifyScreenString.inputTitle".localized(from: self.localizationBundle)
    }

    var resend: String {
        return "VerifyScreenString.resend".localized(from: self.localizationBundle)
    }

    var change: String {
        return "VerifyScreenString.change".localized(from: self.localizationBundle)
    }

    var proceed: String {
        return "VerifyScreenString.proceed".localized(from: self.localizationBundle)
    }

    var done: String {
        return "GlobalString.done".localized(from: self.localizationBundle)
    }

    var title: String {
        return "VerifyScreenString.title".localized(from: self.localizationBundle)
    }

    var invalidCode: String {
        return ClientError.invalidCode.localized(from: self.localizationBundle)
    }
}
