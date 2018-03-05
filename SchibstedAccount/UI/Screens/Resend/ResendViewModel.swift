//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class ResendViewModel {
    let identifier: Identifier
    let localizationBundle: Bundle

    init(identifier: Identifier, localizationBundle: Bundle) {
        self.identifier = identifier
        self.localizationBundle = localizationBundle
    }
}

extension ResendViewModel {
    var header: String {
        return "ResendScreenString.header".localized(from: self.localizationBundle)
    }

    var subtext: String {
        return "ResendScreenString.subtext".localized(from: self.localizationBundle)
    }

    var editText: String {
        switch self.identifier {
        case .phone:
            return "ResendScreenString.edit.phone".localized(from: self.localizationBundle)
        case .email:
            return "ResendScreenString.edit.email".localized(from: self.localizationBundle)
        }
    }

    var proceed: String {
        return "ResendScreenString.proceed".localized(from: self.localizationBundle)
    }
}
