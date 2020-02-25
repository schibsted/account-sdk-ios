//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class FetchStatusInteractor {
    let identityManager: IdentityManager

    init(identityManager: IdentityManager) {
        self.identityManager = identityManager
    }

    func fetchStatus(for identifier: Identifier, completion: @escaping IdentifierStatusResultCallback) {
        identityManager.fetchStatus(for: identifier, completion: completion)
    }
}
