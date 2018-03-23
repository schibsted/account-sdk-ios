//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class SigninInteractor {
    let identityManager: IdentityManager

    init(identityManager: IdentityManager) {
        self.identityManager = identityManager
    }

    func login(username: Identifier, password: String, persistUser: Bool, completion: @escaping (Result<User, ClientError>) -> Void) {
        self.identityManager.login(username: username, password: password, persistUser: persistUser) { [weak self] result in
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
