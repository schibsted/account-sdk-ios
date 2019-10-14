//
//  OneStepCoordinator.swift
//  SchibstedAccount
//
//  Copyright © 2019 Schibsted. All rights reserved.
//

import UIKit

class OneStepCoordinator: FlowCoordinator {
    // TODO handle signup by checking if identifier is available first?
    var child: ChildFlowCoordinator?

    let navigationController: UINavigationController

    let configuration: IdentityUIConfiguration

    enum Output {
        case success(user: User, persistUser: Bool)
        case cancel
        case back
        case error(ClientError?)
    }

    struct Input {
        let localizedTeaserText: String?
        let scopes: [String]
    }

    private let identityManager: IdentityManager
    private let signinInteractor: SigninInteractor

    init(navigationController: UINavigationController, identityManager: IdentityManager, configuration: IdentityUIConfiguration) {
        self.navigationController = navigationController
        self.identityManager = identityManager
        self.configuration = configuration
        self.signinInteractor = SigninInteractor(identityManager: identityManager)
    }

    func start(input: Input, completion: @escaping (Output) -> Void) {
        // TODO what about biometrics login here?
        // TODO what about autofill of email?
        self.showView(localizedTeaserText: input.localizedTeaserText, scopes: input.scopes, completion: completion)
    }
}

extension OneStepCoordinator {
    private func showView(
        localizedTeaserText: String?,
        scopes: [String],
        completion: @escaping (Output) -> Void
    ) {
        let navigationSettings = NavigationSettings(
            cancel: configuration.isCancelable ? { completion(.cancel) } : nil
        )
        let viewModel = OneStepViewModel(
            localizedTeaserText: localizedTeaserText,
            localizationBundle: self.configuration.localizationBundle
        )

        let viewController = OneStepViewController(configuration: self.configuration, navigationSettings: navigationSettings, viewModel: viewModel)
        viewController.didRequestAction = {[weak self] action in
            switch action {
            case let .enter(identifier, password, shouldPersistUser):
                self?.submit(password: password, for: identifier, persistUser: shouldPersistUser, scopes: scopes, completion: completion)

            }
        }

        self.navigationController.pushViewController(viewController, animated: true)
    }

    private func submit(
        password: String,
        for identifier: Identifier,
        persistUser: Bool,
        scopes: [String],
        completion: @escaping (Output) -> Void
        ) {
        self.presentedViewController?.startLoading() // TODO
        self.signinInteractor.login(username: identifier, password: password, scopes: scopes) { [weak self] result in
            self?.presentedViewController?.endLoading()

            switch result {
            case let .success(currentUser):
                self?.configuration.tracker?.loginID = currentUser.legacyID
                self?.spawnCompleteProfileCoordinator(currentUser: currentUser, persistUser: persistUser, completion: completion)
            case let .failure(error):
                if self?.presentedViewController?.showInlineError(error) == true {
                    return
                }
            }
        }
    }
}

extension OneStepCoordinator {
    private func spawnCompleteProfileCoordinator(currentUser: User, persistUser: Bool, completion: @escaping (Output) -> Void) {
        let completeProfileInteractor = UpdateProfileInteractor(currentUser: currentUser, loginFlowVariant: .signin, tracker: self.configuration.tracker)

        let completeProfileCoordinator = CompleteProfileCoordinator(
            navigationController: self.navigationController,
            identityManager: self.identityManager,
            configuration: self.configuration
        )

        self.spawnChild(completeProfileCoordinator, input: completeProfileInteractor) { [weak self] output in
            switch output {
            case let .success(currentUser):
                completion(.success(user: currentUser, persistUser: persistUser))
            case .cancel:
                completion(.cancel)
            case .back:
                self?.navigationController.popViewController(animated: true)
            case let .error(error):
                self?.present(error: error)
            case .reset:
                //TODO
                break
            }
        }
    }
}
