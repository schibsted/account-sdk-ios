//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class OneTimeCodeInteractor {
    let identityManager: IdentityManager

    init(identityManager: IdentityManager) {
        self.identityManager = identityManager
    }

    func sendCode(to identifier: Identifier, completion: @escaping NoValueCallback) {
        self.identityManager.sendCode(to: identifier, completion: completion)
    }

    func resendCode(to identifier: Identifier, completion: @escaping NoValueCallback) {
        self.identityManager.resendCode(to: identifier, completion: completion)
    }

    func validate(oneTimeCode: String, for identifier: Identifier, scopes: [String], completion: @escaping (Result<User, ClientError>) -> Void) {
        self.identityManager.validate(oneTimeCode: oneTimeCode, for: identifier, scopes: scopes, persistUser: false) { [weak self] result in
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
