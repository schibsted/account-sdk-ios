//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class TermsCoordinator: FlowCoordinator {
    enum Output {
        case success
        case cancel
        case error(ClientError)
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
        self.termsInteractor.fetchTerms { [weak self] result in
            switch result {
            case let .success(terms):
                self?.showAcceptTermsView(for: terms, completion: completion)
            case let .failure(error):
                if self?.handle(error: error) != true { completion(.error(error)) }
            }
        }
    }
}

extension TermsCoordinator {
    private func showAcceptTermsView(
        for terms: Terms,
        completion: @escaping (Output) -> Void
    ) {
        let navigationSettings = NavigationSettings(
            cancel: configuration.isCancelable ? { completion(.cancel) } : nil,
            back: { completion(.cancel) }
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

extension TermsCoordinator {
    private func handle(error: ClientError) -> Bool {
        if self.presentedViewController is TermsViewController || self.presentedViewController is RequiredFieldsViewController {
            self.present(error: error)
            return true
        }
        return false
    }
}
