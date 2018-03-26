//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class LoadingViewModel {
    let localizationBundle: Bundle

    init(localizationBundle: Bundle) {
        self.localizationBundle = localizationBundle
    }
}

extension LoadingViewModel {
    var title: String {
        return "TermsScreenString.title".localized(from: self.localizationBundle)
    }
}
