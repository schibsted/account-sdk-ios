//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class SigninInteractor {
    let identityManager: IdentityManager

    init(identityManager: IdentityManager) {
        self.identityManager = identityManager
    }

    func login(username: Identifier, password: String, scopes: [String],
               useSharedWebCredentials: Bool, completion: @escaping (Result<User, ClientError>) -> Void) {
        identityManager.login(username: username, password: password, scopes: scopes, persistUser: false,
                              useSharedWebCredentials: useSharedWebCredentials) { [weak self] result in
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
