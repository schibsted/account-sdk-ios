//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class UpdateUserProfileTask: TaskProtocol {
    private weak var user: User?
    private var profile: UserProfile

    init(user: User?, profile: UserProfile) {
        self.user = user
        self.profile = profile
    }

    func execute(completion: @escaping NoValueCallback) {
        guard let user = self.user, let tokens = user.tokens, let userID = tokens.anyUserID else {
            completion(.failure(.invalidUser))
            return
        }

        user.api.updateUserProfile(
            userID: userID,
            oauthToken: tokens.accessToken,
            profile: self.profile
        ) { [weak self] result in
            guard self?.user != nil else {
                completion(.failure(.invalidUser))
                return
            }
            switch result {
            case .success:
                completion(.success(()))
            case let .failure(error):
                completion(.failure(ClientError(error)))
            }
        }
    }
}
