//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class ClientInfoInteractor {
    let identityManager: IdentityManager

    init(identityManager: IdentityManager) {
        self.identityManager = identityManager
    }

    func fetchClient(completion: @escaping ClientResultCallback) {
        self.identityManager.fetchClient(completion: completion)
    }
}
