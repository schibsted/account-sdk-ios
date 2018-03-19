//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class SignupInteractor: CompleteProfileInteractor {
    let identifier: Identifier
    let password: String
    let persistUser: Bool
    let identityManager: IdentityManager
    let currentUser: User? = nil
    let loginFlowVariant: LoginMethod.FlowVariant = .signup

    init(identifier: Identifier, password: String, persistUser: Bool, identityManager: IdentityManager) {
        self.identifier = identifier
        self.password = password
        self.persistUser = persistUser
        self.identityManager = identityManager
    }

    func completeProfile(
        acceptingTerms: Bool,
        requiredFieldsToUpdate: [SupportedRequiredField: String],
        completion: @escaping (Result<User, ClientError>) -> Void
    ) {
        var profile = UserProfile()

        for (field, value) in requiredFieldsToUpdate {
            profile.set(field: field, value: value)
        }

        self.identityManager.signup(
            username: self.identifier,
            password: self.password,
            profile: profile,
            acceptTerms: acceptingTerms,
            persistUser: self.persistUser
        ) { [weak self] result in
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
