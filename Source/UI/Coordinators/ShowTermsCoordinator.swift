//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class ShowTermsCoordinator: FlowCoordinator {
    struct Input {
        enum PresentationStyle {
            case replaceNavigationFlow
            case pushToExistingNavigationFlow

            fileprivate var hasBackButton: Bool {
                switch self {
                case .replaceNavigationFlow:
                    return false
                case .pushToExistingNavigationFlow:
                    return true
                }
            }
        }

        let terms: Terms
        let loginFlowVariant: LoginMethod.FlowVariant
        let presentationStyle: PresentationStyle
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
        self.showAcceptTermsView(
            for: input.terms,
            loginFlowVariant: input.loginFlowVariant,
            presentationStyle: input.presentationStyle,
            completion: completion
        )
    }
}

extension ShowTermsCoordinator {
    private func showAcceptTermsView(
        for terms: Terms,
        loginFlowVariant: LoginMethod.FlowVariant,
        presentationStyle: Input.PresentationStyle,
        completion: @escaping (Output) -> Void
    ) {
        let navigationSettings = NavigationSettings(
            cancel: { completion(.cancel) },
            back: presentationStyle.hasBackButton ? { completion(.back) } : nil
        )
        let viewModel = TermsViewModel(
            terms: terms,
            loginFlowVariant: loginFlowVariant,
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
            case .back:
                completion(.back)
            case .cancel:
                completion(.cancel)
            }
        }

        switch presentationStyle {
        case .pushToExistingNavigationFlow:
            self.navigationController.pushViewController(viewController, animated: true)
        case .replaceNavigationFlow:
            self.navigationController.viewControllers = [viewController]
        }
    }

    private func showTermsSummaryView(_ summary: String) {
        let viewModel = TermsSummaryViewModel(summary: summary, localizationBundle: self.configuration.localizationBundle)
        let viewController = TermsSummaryViewController(configuration: self.configuration, viewModel: viewModel)
        self.presentAsPopup(viewController)
    }
}
