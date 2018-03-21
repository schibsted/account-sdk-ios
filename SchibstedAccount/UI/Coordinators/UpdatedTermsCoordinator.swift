//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class UpdatedTermsCoordinator: FlowCoordinator {
    enum Output {
        case success
        case cancel
    }

    let navigationController: UINavigationController
    let identityManager: IdentityManager
    let configuration: IdentityUIConfiguration

    var child: ChildFlowCoordinator?

    private let termsInteractor: TermsInteractor

    init(
        navigationController: UINavigationController,
        identityManager: IdentityManager,
        configuration: IdentityUIConfiguration
    ) {
        self.navigationController = navigationController
        self.identityManager = identityManager
        self.configuration = configuration
        self.termsInteractor = TermsInteractor(identityManager: identityManager)
    }

    func start(input _: Void, completion: @escaping (Output) -> Void) {
        let loadingViewController = showLoadingView(didCancel: { completion(.cancel) })
        loadingViewController.startLoading()

        self.termsInteractor.fetchTerms { [weak self] result in
            switch result {
            case let .success(terms):
                loadingViewController.endLoading { [weak self] in
                    self?.showAcceptTermsView(for: terms, completion: completion)
                }
            case let .failure(error):
                loadingViewController.endLoading()
                self?.present(error: error) {
                    completion(.cancel)
                }
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
                self?.configuration.tracker?.engagement(.network(.agreementAccepted))
                // TODO: Network call to accept the terms
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

extension UpdatedTermsCoordinator {
    private func showLoadingView(didCancel: @escaping () -> Void) -> LoadingViewController {
        let navigationSettings = NavigationSettings(
            cancel: { didCancel() },
            back: nil
        )
        let viewModel = LoadingViewModel(localizationBundle: self.configuration.localizationBundle)
        let loadingViewController = LoadingViewController(configuration: self.configuration, navigationSettings: navigationSettings, viewModel: viewModel)
        self.navigationController.viewControllers = [loadingViewController]

        return loadingViewController
    }
}
