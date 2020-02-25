//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

///
class IdentifierViewModel {
    let loginMethod: LoginMethod
    let localizedTeaserText: String?
    let localizationBundle: Bundle
    let kind: Client.Kind
    let merchantName: String
    let locale: Locale

    var helpURL: URL {
        guard let url = URL(string: "https://info.privacy.schibsted.com/" + locale.gdprLanguageCode + "/S010") else {
            preconditionFailure("Failed to make help me URL")
        }
        return url
    }

    init(
        loginMethod: LoginMethod,
        kind: Client.Kind?,
        merchantName: String,
        localizedTeaserText: String?,
        localizationBundle: Bundle,
        locale: Locale
    ) {
        self.loginMethod = loginMethod
        self.kind = kind ?? .internal
        self.merchantName = merchantName
        self.localizedTeaserText = localizedTeaserText
        self.localizationBundle = localizationBundle
        self.locale = locale
    }
}

private extension NSMutableString {
    @discardableResult
    func replace(string target: String, with value: String) -> NSRange? {
        let range = self.range(of: target)
        if range.location != NSNotFound {
            replaceCharacters(in: range, with: value)
            return NSRange(location: range.location, length: value.count)
        }
        return nil
    }
}

extension IdentifierViewModel {
    var infoText: String {
        let startText: String
        switch kind {
        case .internal:
            startText = "IdentifierScreenString.infoText.internal".localized(from: localizationBundle)
        case .external:
            startText = "IdentifierScreenString.infoText.external".localized(from: localizationBundle)
        }

        let mutableString = NSMutableString(string: startText)
        mutableString.replace(string: "$0", with: merchantName)
        return mutableString as String + " " + "IdentifierScreenString.infoText.rest".localized(from: localizationBundle)
    }

    var proceed: String {
        return "IdentifierScreenString.proceed".localized(from: localizationBundle)
    }

    var skip: String {
        return "IdentifierScreenString.skip".localized(from: localizationBundle)
    }

    var inputTitle: String {
        switch loginMethod.methodType {
        case .email:
            return "IdentifierScreenString.inputTitle.email".localized(from: localizationBundle)
        case .phone:
            return "IdentifierScreenString.inputTitle.phone".localized(from: localizationBundle)
        case .password:
            return "IdentifierScreenString.inputTitle.password".localized(from: localizationBundle)
        }
    }

    var title: String {
        switch loginMethod.identifierType {
        case .email:
            return "IdentifierScreenString.title.email".localized(from: localizationBundle)
        case .phone:
            return "IdentifierScreenString.title.sms".localized(from: localizationBundle)
        }
    }

    var done: String {
        return "GlobalString.done".localized(from: localizationBundle)
    }

    var invalidEmail: String {
        return ClientError.invalidEmail.localized(from: localizationBundle)
    }

    var invalidPhoneNumber: String {
        return ClientError.invalidPhoneNumber.localized(from: localizationBundle)
    }

    var whatsThis: String {
        return "IdentifierScreenString.whatsThis".localized(from: localizationBundle)
    }
}
