//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class TermsInteractor {
    let identityManager: IdentityManager

    init(identityManager: IdentityManager) {
        self.identityManager = identityManager
    }

    func fetchStatus(for user: User, completion: @escaping BoolResultCallback) {
        user.agreements.status(completion: completion)
    }

    func fetchTerms(completion: @escaping TermsResultCallback) {
        self.identityManager.fetchTerms(completion: completion)
    }
}
