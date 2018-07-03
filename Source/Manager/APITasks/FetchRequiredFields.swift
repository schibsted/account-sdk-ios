//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class FetchRequiredFieldsTask: TaskProtocol {
    private weak var user: User?

    init(user: User?) {
        self.user = user
    }

    func execute(completion: @escaping RequiredFieldsResultCallback) {
        guard let user = self.user, let tokens = user.tokens, let userID = tokens.anyUserID else {
            completion(.failure(.invalidUser))
            return
        }

        user.api.fetchRequiredFields(oauthToken: tokens.accessToken, userID: userID) { [weak self] result in
            guard let strongSelf = self else { return }

            guard strongSelf.user != nil else {
                completion(.failure(.invalidUser))
                return
            }

            switch result {
            case let .success(model):
                completion(.success(model.fields))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
