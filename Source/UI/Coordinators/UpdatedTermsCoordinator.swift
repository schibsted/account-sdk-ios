//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class UpdatedTermsCoordinator: FlowCoordinator {
    struct Input {
        let currentUser: User
        let terms: Terms
    }

    enum Output {
        case success
        case cancel
    }

    let navigationController: UINavigationController
    let configuration: IdentityUIConfiguration

    var child: ChildFlowCoordinator?

    private var userTermsInteractor: UserTermsInteractor?

    init(navigationController: UINavigationController, configuration: IdentityUIConfiguration) {
        self.navigationController = navigationController
        self.configuration = configuration
    }

    func start(input: Input, completion: @escaping (Output) -> Void) {
        let userTermsInteractor = UserTermsInteractor(user: input.currentUser)
        self.userTermsInteractor = userTermsInteractor
        self.spawnShowTermsCoordinator(with: input.terms, userTermsInteractor: userTermsInteractor, completion: completion)
    }
}

extension UpdatedTermsCoordinator {
    private func spawnShowTermsCoordinator(with terms: Terms, userTermsInteractor: UserTermsInteractor, completion: @escaping (Output) -> Void) {
        let showTermsCoordinator = ShowTermsCoordinator(navigationController: self.navigationController, configuration: self.configuration)
        let input = ShowTermsCoordinator.Input(terms: terms, loginFlowVariant: .signin)

        self.spawnChild(showTermsCoordinator, input: input) { [weak self] output in
            switch output {
            case .success:
                userTermsInteractor.acceptTerms { [weak self] result in
                    switch result {
                    case .success:
                        completion(.success)
                    case let .failure(error):
                        self?.present(error: error)
                    }
                }
            case .cancel, .back:
                // Since user has not accepted the updated terms, we force a logout :'(
                userTermsInteractor.user.logout()
                completion(.cancel)
            }
        }
    }
}
