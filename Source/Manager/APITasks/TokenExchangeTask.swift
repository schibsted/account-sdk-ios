//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class TokenExchangeTask: TaskProtocol {
    private weak var user: User?
    private var type: TokenExchangeType
    private var redirectURL: URL?
    private let clientID: String

    init(user: User?, clientID: String, type: TokenExchangeType, redirectURL: URL?) {
        self.user = user
        self.clientID = clientID
        self.type = type
        self.redirectURL = redirectURL
    }

    func execute(completion: @escaping (Result<String, ClientError>) -> Void) {
        guard let user = self.user, let tokens = user.tokens else {
            completion(.failure(.invalidUser))
            return
        }

        user.api.tokenExchange(
            oauthToken: tokens.accessToken,
            clientID: clientID,
            type: type,
            redirectURI: redirectURL?.absoluteString
        ) { [weak self] result in
            guard let strongSelf = self else { return }

            guard strongSelf.user != nil else {
                completion(.failure(.invalidUser))
                return
            }

            switch result {
            case let .success(model):
                completion(.success(model.code))
            case let .failure(error):
                completion(.failure(ClientError(error)))
            }
        }
    }
}
