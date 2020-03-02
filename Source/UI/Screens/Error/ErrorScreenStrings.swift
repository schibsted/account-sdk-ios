//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

struct ErrorScreenStrings {
    let localizationBundle: Bundle
    init(localizationBundle: Bundle) {
        self.localizationBundle = localizationBundle
    }

    var heading: String {
        return "ErrorScreenString.heading".localized(from: localizationBundle)
    }

    var proceed: String {
        return "ErrorScreenString.proceed".localized(from: localizationBundle)
    }
}
