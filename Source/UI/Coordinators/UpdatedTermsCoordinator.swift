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

        self.showAcceptTermsView(for: input.terms) { [weak self] result in
            switch result {
            case .success:
                userTermsInteractor.acceptTerms { [weak self] result in
                    switch result {
                    case .success:
                        self?.configuration.tracker?.engagement(.network(.agreementAccepted))
                        completion(.success)
                    case let .failure(error):
                        self?.present(error: error)
                    }
                }
            case .cancel:
                completion(.cancel)
            }
        }
    }
}

extension UpdatedTermsCoordinator {
    private func showAcceptTermsView(
        for terms: Terms,
        completion: @escaping (Output) -> Void
    ) {
        let navigationSettings = NavigationSettings(
            cancel: { completion(.cancel) },
            back: nil
        )
        let viewModel = TermsViewModel(
            terms: terms,
            loginFlowVariant: .signin,
            appName: self.configuration.appName,
            localizationBundle: self.configuration.localizationBundle
        )

        let viewController = TermsViewController(configuration: self.configuration, navigationSettings: navigationSettings, viewModel: viewModel)
        viewController.didRequestAction = { [weak self] action in
            switch action {
            case .acceptTerms:
                completion(.success)
            case let .learnMore(summary):
                self?.showTermsSummaryView(summary)
            case let .open(url):
                self?.present(url: url)
            case .back, .cancel:
                completion(.cancel)
            }
        }

        self.navigationController.viewControllers = [viewController]
    }

    private func showTermsSummaryView(_ summary: String) {
        let viewModel = TermsSummaryViewModel(summary: summary, localizationBundle: self.configuration.localizationBundle)
        let viewController = TermsSummaryViewController(configuration: self.configuration, viewModel: viewModel)
        self.presentAsPopup(viewController)
    }
}
