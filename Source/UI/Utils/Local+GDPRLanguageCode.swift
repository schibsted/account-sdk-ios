//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension Locale {
    var gdprLanguageCode: String {
        guard let code = self.languageCode else {
            return "en"
        }
        switch code {
        case "nb", "no", "nn":
            return "no"
        case "sv":
            return "se"
        case "fi":
            return "fi"
        default:
            return "en"
        }
    }
}
