//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class AuthenticationCodeInteractor {
    let identityManager: IdentityManager

    init(identityManager: IdentityManager) {
        self.identityManager = identityManager
    }

    func validate(authCode: String, codeVerifier: String? = nil, completion: @escaping (Result<User, ClientError>) -> Void) {
        identityManager.validate(authCode: authCode, persistUser: false, codeVerifier: codeVerifier) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success:
                completion(.success(strongSelf.identityManager.currentUser))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
