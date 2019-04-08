//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
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
            log(from: self, "found agreements status in cache - \(agreements)")
            completion(.success(agreements.client && agreements.platform))
            return
        }

        user.api.fetchAgreementsAcceptanceStatus(
            oauthToken: tokens.accessToken,
            userID: userID
        ) { [weak self] result in
            guard let strongSelf = self else { return }

            do {
                guard strongSelf.user != nil else {
                    throw ClientError.invalidUser
                }

                let agreements = try result.materialize()
                log(from: self, "fetch agreements status - \(agreements)")

                agreementsCache.store(agreements, forUserID: userID)
                log(level: .verbose, from: self, "stored agreements to cache")

                completion(.success(agreements.client && agreements.platform))
            } catch {
                log(level: .error, from: self, "\(error)")
                completion(.failure(ClientError(error)))
            }
        }
    }
}
