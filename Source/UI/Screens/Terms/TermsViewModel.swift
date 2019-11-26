//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

private extension NSMutableString {
    func replace(string target: String, with value: String) -> NSRange? {
        let range = self.range(of: target)
        if range.location != NSNotFound {
            replaceCharacters(in: range, with: value)
            return NSRange(location: range.location, length: value.count)
        }
        return nil
    }
}

private extension String {
    func expand(with text: String, link url: URL) -> NSAttributedString? {
        let mutableString = NSMutableString(string: self)
        guard let range = mutableString.replace(string: "$0", with: text) else {
            return nil
        }
        let attributedString = NSMutableAttributedString(string: mutableString as String)
        attributedString.addAttribute(.link, value: url.absoluteString, range: range)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        return attributedString
    }
}

private func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString()
    result.append(lhs)
    result.append(rhs)
    return result
}

class TermsViewModel {
    let terms: Terms
    let appName: String
    let loginFlowVariant: LoginMethod.FlowVariant
    let localizationBundle: Bundle

    init(
        terms: Terms,
        loginFlowVariant: LoginMethod.FlowVariant,
        appName: String,
        localizationBundle: Bundle
    ) {
        self.terms = terms
        self.loginFlowVariant = loginFlowVariant
        self.appName = appName
        self.localizationBundle = localizationBundle
    }

    var termsLink: NSAttributedString {
        guard let platformTermsURL = self.terms.platformTermsURL else {
            return NSAttributedString(string: "<platform terms missing>")
        }
        guard let platformTermsText = self.platformTerms.expand(with: self.platformName, link: platformTermsURL) else {
            return NSAttributedString(string: "<platform terms localization text unexpandable>")
        }
        guard let clientTermsURL = self.terms.clientTermsURL else {
            return platformTermsText
        }
        guard let clientTermsText = self.clientTerms.expand(with: self.appName, link: clientTermsURL) else {
            return NSAttributedString(string: "<client terms localization text unexpandable>")
        }
        return platformTermsText + clientTermsText
    }

    var privacyLink: NSAttributedString {
        guard let platformPrivacyURL = self.terms.platformPrivacyURL else {
            return NSAttributedString(string: "<platform privacy missing>")
        }
        guard let platformPrivacyText = self.platformPrivacy.expand(with: self.platformName, link: platformPrivacyURL) else {
            return NSAttributedString(string: "<platform privacy localization text unexpandable>")
        }
        guard let clientPrivacyURL = self.terms.clientPrivacyURL else {
            return platformPrivacyText
        }
        guard let clientPrivacyText = self.clientPrivacy.expand(with: self.appName, link: clientPrivacyURL) else {
            return NSAttributedString(string: "<client privacy localization text unexpandable>")
        }
        return platformPrivacyText + clientPrivacyText
    }
}

extension TermsViewModel {
    var subtextCreate: String {
        return "TermsScreenString.subtext.create".localized(from: localizationBundle)
    }

    var subtextLogin: String {
        return "TermsScreenString.subtext.login".localized(from: localizationBundle)
    }

    var proceed: String {
        return "TermsScreenString.proceed".localized(from: localizationBundle)
    }

    var acceptTermError: String {
        return "TermsScreenString.acceptTermError".localized(from: localizationBundle)
    }

    var acceptPrivacyError: String {
        return "TermsScreenString.acceptPrivacyError".localized(from: localizationBundle)
    }

    var title: String {
        return "TermsScreenString.title".localized(from: localizationBundle)
    }

    var platformTerms: String {
        return "TermsScreenString.platform.terms".localized(from: localizationBundle)
    }

    var platformPrivacy: String {
        return "TermsScreenString.platform.privacy".localized(from: localizationBundle)
    }

    var clientTerms: String {
        return "TermsScreenString.client.terms".localized(from: localizationBundle)
    }

    var clientPrivacy: String {
        return "TermsScreenString.client.privacy".localized(from: localizationBundle)
    }

    var platformName: String {
        return "GlobalString.platformName".localized(from: localizationBundle)
    }

    var learnMore: String {
        return "TermsScreenString.learnMore".localized(from: localizationBundle)
    }
}
