//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class FetchAgreementsStatusTask: TaskProtocol {
    private weak var user: User?

    init(user: User?) {
        self.user = user
    }

    func execute(completion: @escaping (Result<Bool, ClientError>) -> Void) {
        guard let user = self.user, let tokens = user.tokens, let userID = tokens.anyUserID else {
            completion(.failure(.invalidUser))
            return
        }

        let agreementsCache = SDKConfiguration.shared.agreementsCache
        if let agreements = agreementsCache.load(forUserID: userID) {
            completion(.success(agreements.client && agreements.platform))
            return
        }

        user.api.fetchAgreementsAcceptanceStatus(
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
                agreementsCache.store(model, forUserID: userID)
                let isAccepted = model.client && model.platform
                completion(.success(isAccepted))
            case let .failure(error):
                completion(.failure(ClientError(error)))
            }
        }
    }
}
