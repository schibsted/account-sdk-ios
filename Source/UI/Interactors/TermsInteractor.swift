//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class TermsInteractor {
    let identityManager: IdentityManager

    init(identityManager: IdentityManager) {
        self.identityManager = identityManager
    }

    func fetchTerms(completion: @escaping TermsResultCallback) {
        identityManager.fetchTerms(completion: completion)
    }
}
