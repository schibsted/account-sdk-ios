//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class FetchTermsTask: TaskProtocol {
    private weak var user: User?

    init(user: User?) {
        self.user = user
    }

    func execute(completion: @escaping TermsResultCallback) {
        guard let user = self.user else {
            completion(.failure(.invalidUser))
            return
        }

        user.api.fetchTerms(
            clientID: user.clientConfiguration.clientID
        ) { [weak self] result in

            log(from: self, result)

            guard self != nil else { return }

            switch result {
            case let .success(terms):
                completion(.success(terms))
            case let .failure(error):
                completion(.failure(ClientError(error)))
            }
        }
    }
}
