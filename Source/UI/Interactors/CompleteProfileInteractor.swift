//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

protocol CompleteProfileInteractor {
    var currentUser: User? { get }
    var loginFlowVariant: LoginMethod.FlowVariant { get }

    func completeProfile(
        acceptingTerms: Bool,
        requiredFieldsToUpdate: [SupportedRequiredField: String],
        completion: @escaping (Result<User, ClientError>) -> Void
    )
}
