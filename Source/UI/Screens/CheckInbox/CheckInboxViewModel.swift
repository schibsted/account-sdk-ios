//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class CheckInboxViewModel {
    let identifier: Identifier
    let localizationBundle: Bundle

    init(identifier: Identifier, localizationBundle: Bundle) {
        self.identifier = identifier
        self.localizationBundle = localizationBundle
    }
}

extension CheckInboxViewModel {
    var sentLink: String {
        return "CheckInboxScreenStrings.sentLink".localized(from: localizationBundle)
    }

    var change: String {
        return "CheckInboxScreenStrings.change".localized(from: localizationBundle)
    }

    var title: String {
        return "CheckInboxScreenStrings.title".localized(from: localizationBundle)
    }
}
