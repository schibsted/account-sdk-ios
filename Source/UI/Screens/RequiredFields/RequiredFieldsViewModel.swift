//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class RequiredFieldsViewModel {
    let supportedRequiredFields: [SupportedRequiredField]
    let localizationBundle: Bundle

    init(requiredFields: [RequiredField], localizationBundle: Bundle) {
        self.supportedRequiredFields = SupportedRequiredField.from(requiredFields)
        self.localizationBundle = localizationBundle
    }
}

extension RequiredFieldsViewModel {
    var done: String {
        return "GlobalString.done".localized(from: self.localizationBundle)
    }

    func titleForField(at index: Int) -> String {
        let localizedKey: String
        switch self.supportedRequiredFields[index] {
        case .givenName:
            localizedKey = "RequiredField.givenName.title"
        case .familyName:
            localizedKey = "RequiredField.familyName.title"
        case .birthday:
            localizedKey = "RequiredField.birthday.title"
        }
        return localizedKey.localized(from: self.localizationBundle)
    }

    func requiredFieldID(at index: Int) -> String {
        return self.supportedRequiredFields[index].rawValue
    }

    func placeholderForField(at index: Int) -> String? {
        let localizedKey: String?
        switch self.supportedRequiredFields[index] {
        case .birthday:
            localizedKey = "RequiredField.birthday.placeholder"
        case .givenName, .familyName:
            localizedKey = nil
        }
        return localizedKey?.localized(from: self.localizationBundle)
    }

    var proceed: String {
        return "RequiredFieldsScreenString.proceed".localized(from: self.localizationBundle)
    }

    var title: String {
        return "RequiredFieldsScreenString.title".localized(from: self.localizationBundle)
    }

    var subtext: String {
        return "RequiredFieldsScreenString.subtext".localized(from: self.localizationBundle)
    }

    func string(for error: SupportedRequiredField.ValidationError) -> String {
        switch error {
        case .missing:
            return "RequiredField.error.missing".localized(from: self.localizationBundle)
        case .lessThanThree:
            return "RequiredField.error.lessThanThree".localized(from: self.localizationBundle)
        case .dateInvalid:
            return "RequiredField.error.birthdateInvalid".localized(from: self.localizationBundle)
        }
    }
}
