//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class AcceptAgreementsTask: TaskProtocol {
    private weak var user: User?

    init(user: User?) {
        self.user = user
    }

    func execute(completion: @escaping (Result<NoValue, ClientError>) -> Void) {
        guard let user = self.user, let tokens = user.tokens, let userID = tokens.anyUserID else {
            completion(.failure(.invalidUser))
            return
        }

        user.api.acceptAgreements(
            oauthToken: tokens.accessToken,
            userID: userID
        ) { [weak self] result in

            guard let strongSelf = self else { return }

            log(from: self, result)

            guard strongSelf.user != nil else {
                completion(.failure(.invalidUser))
                return
            }

            switch result {
            case .success:
                SDKConfiguration.shared.agreementsCache.store(Agreements(acceptanceStatus: true), forUserID: userID)
                log(from: self, "stored agreements to cache")
                completion(.success(()))
            case let .failure(error):
                completion(.failure(ClientError(error)))
            }
        }
    }
}
