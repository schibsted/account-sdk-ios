//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class FetchUserAssetsTask: TaskProtocol {
    private weak var user: User?

    init(user: User?) {
        self.user = user
    }

    func execute(completion: @escaping UserAssetsResultCallback) {
        guard let user = self.user, let tokens = user.tokens, let userID = tokens.anyUserID else {
            completion(.failure(.invalidUser))
            return
        }

        user.api.fetchUserAssets(
            oauthToken: tokens.accessToken,
            userID: userID
        ) { [weak self] result in
            log(from: self, result)

            guard let strongSelf = self else { return }

            guard strongSelf.user != nil else {
                completion(.failure(.invalidUser))
                return
            }

            switch result {
            case let .success(model):
                completion(.success(model.assets))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
