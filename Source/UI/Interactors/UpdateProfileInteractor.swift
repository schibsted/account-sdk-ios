//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class UpdateProfileInteractor: CompleteProfileInteractor {
    let currentUser: User?
    let tracker: TrackingEventsHandler?
    let loginFlowVariant: LoginMethod.FlowVariant

    init(currentUser: User, loginFlowVariant: LoginMethod.FlowVariant, tracker: TrackingEventsHandler?) {
        self.currentUser = currentUser
        self.loginFlowVariant = loginFlowVariant
        self.tracker = tracker
    }

    func completeProfile(
        acceptingTerms: Bool,
        requiredFieldsToUpdate: [SupportedRequiredField: String],
        completion: @escaping (Result<User, ClientError>) -> Void
    ) {
        if !acceptingTerms {
            updateRequiredFields(requiredFieldsToUpdate, completion: completion)
            return
        }

        currentUser?.agreements.accept { [weak self] result in
            switch result {
            case .success:
                self?.updateRequiredFields(requiredFieldsToUpdate, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func updateRequiredFields(_ requiredFieldsToUpdate: [SupportedRequiredField: String], completion: @escaping (Result<User, ClientError>) -> Void) {
        guard let currentUser = self.currentUser else {
            return
        }

        if requiredFieldsToUpdate.count <= 0 {
            completion(.success(currentUser))
            return
        }

        self.currentUser?.profile.fetch { [weak self] result in
            do {
                var newProfile = try result.materialize()
                for (field, value) in requiredFieldsToUpdate {
                    newProfile.set(field: field, value: value)
                }

                self?.currentUser?.profile.update(newProfile) { result in
                    switch result {
                    case .success:
                        completion(.success(currentUser))
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }

            } catch {
                completion(.failure(ClientError(error)))
            }
        }
    }
}
