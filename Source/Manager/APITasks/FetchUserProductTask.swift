//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class FetchUserProductTask: TaskProtocol {
    private weak var user: User?
    private let productID: String

    init(user: User?, productID: String) {
        self.user = user
        self.productID = productID
    }

    func execute(completion: @escaping (Result<UserProduct, ClientError>) -> Void) {
        guard let user = self.user, let tokens = user.tokens, let userID = tokens.anyUserID else {
            completion(.failure(.invalidUser))
            return
        }

        user.api.fetchUserProduct(
            oauthToken: tokens.accessToken,
            userID: userID,
            productID: self.productID
        ) { [weak self] result in
            guard let strongSelf = self else { return }

            guard strongSelf.user != nil else {
                completion(.failure(.invalidUser))
                return
            }

            completion(result)
        }
    }
}
