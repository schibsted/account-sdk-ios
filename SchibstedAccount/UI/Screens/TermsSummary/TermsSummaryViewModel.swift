//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class TermsSummaryViewModel {
    let summary: String
    let localizationBundle: Bundle

    init(summary: String, localizationBundle: Bundle) {
        self.summary = summary
        self.localizationBundle = localizationBundle
    }
}

extension TermsSummaryViewModel {
    var title: String {
        return "TermsSummaryScreenString.title".localized(from: self.localizationBundle)
    }
}
