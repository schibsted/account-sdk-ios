//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class UserTermsInteractor {
    let user: User

    init(user: User) {
        self.user = user
    }

    func fetchStatus(completion: @escaping BoolResultCallback) {
        self.user.agreements.status(completion: completion)
    }

    func acceptTerms(completion: @escaping NoValueCallback) {
        self.user.agreements.accept(completion: completion)
    }
}
