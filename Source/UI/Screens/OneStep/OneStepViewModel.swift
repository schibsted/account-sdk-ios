//
//  OneStepViewModel.swift
//  SchibstedAccount
//

import Foundation

class OneStepViewModel {
    let localizedTeaserText: String?
    let localizationBundle: Bundle
    let kind: Client.Kind
    let merchantName: String
    let locale: Locale

    init(
        kind: Client.Kind?,
        merchantName: String,
        localizedTeaserText: String?,
        localizationBundle: Bundle,
        locale: Locale
    ) {
        self.kind = kind ?? .internal
        self.merchantName = merchantName
        self.localizedTeaserText = localizedTeaserText
        self.localizationBundle = localizationBundle
        self.locale = locale
    }
}
