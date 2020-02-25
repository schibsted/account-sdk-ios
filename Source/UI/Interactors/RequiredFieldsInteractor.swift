//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class RequiredFieldsInteractor {
    let identityManager: IdentityManager

    init(identityManager: IdentityManager) {
        self.identityManager = identityManager
    }

    func fetchRequiredFields(for user: User, completion: @escaping RequiredFieldsResultCallback) {
        user.profile.requiredFields(completion: completion)
    }

    func fetchClientRequiredFields(completion: @escaping RequiredFieldsResultCallback) {
        identityManager.requiredFields(completion: completion)
    }
}
