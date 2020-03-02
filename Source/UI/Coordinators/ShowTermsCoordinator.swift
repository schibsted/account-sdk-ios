//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class ShowTermsCoordinator: FlowCoordinator {
    struct Input {
        let terms: Terms
        let loginFlowVariant: LoginMethod.FlowVariant
    }

    enum Output {
        case success
        case cancel
        case back
    }

    let navigationController: UINavigationController
    let configuration: IdentityUIConfiguration

    var child: ChildFlowCoordinator?

    init(navigationController: UINavigationController, configuration: IdentityUIConfiguration) {
        self.navigationController = navigationController
        self.configuration = configuration
    }

    func start(input: Input, completion: @escaping (Output) -> Void) {
        showAcceptTermsView(
            for: input.terms,
            loginFlowVariant: input.loginFlowVariant,
            completion: completion
        )
    }
}

extension ShowTermsCoordinator {
    private func showAcceptTermsView(
        for terms: Terms,
        loginFlowVariant: LoginMethod.FlowVariant,
        completion: @escaping (Output) -> Void
    ) {
        let isFirstViewController = navigationController.viewControllers.count == 0

        let navigationSettings = NavigationSettings(
            cancel: { completion(.cancel) },
            back: isFirstViewController ? nil : { completion(.back) }
        )
        let viewModel = TermsViewModel(
            terms: terms,
            loginFlowVariant: loginFlowVariant,
            appName: configuration.appName,
            localizationBundle: configuration.localizationBundle
        )

        let viewController = TermsViewController(configuration: configuration, navigationSettings: navigationSettings, viewModel: viewModel)
        viewController.didRequestAction = { [weak self] action in
            switch action {
            case .acceptTerms:
                completion(.success)
            case let .open(url):
                self?.present(url: url)
            case .back:
                completion(.back)
            case .cancel:
                completion(.cancel)
            }
        }

        if isFirstViewController {
            navigationController.viewControllers = [viewController]
        } else {
            navigationController.pushViewController(viewController, animated: true)
        }
    }
}
