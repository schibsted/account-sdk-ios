//
//  OneStepCoordinator.swift
//  SchibstedAccount
//
//  Copyright © 2019 Schibsted. All rights reserved.
//

import UIKit

class OneStepCoordinator: FlowCoordinator {
    // TODO handle signup
    var child: ChildFlowCoordinator?

    let navigationController: UINavigationController

    let configuration: IdentityUIConfiguration

    enum Output {
        case success(user: User)
        case cancel
        case back
    }

    struct Input {
        let identifier: Identifier
        let password: String
        let persistUser: Bool
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
        self.submit(password: input.password, for: input.identifier, persistUser: input.persistUser, scopes: input.scopes, completion: completion)
    }
}

extension OneStepCoordinator {
    private func submit(
        password: String,
        for identifier: Identifier,
        persistUser: Bool,
        scopes: [String],
        completion: @escaping (Output) -> Void
        ) {
        self.presentedViewController?.startLoading()
        self.signinInteractor.login(username: identifier, password: password, scopes: scopes) { [weak self] result in
            self?.presentedViewController?.endLoading()

            switch result {
            case let .success(currentUser):
                self?.configuration.tracker?.loginID = currentUser.legacyID
                self?.spawnCompleteProfileCoordinator(currentUser: currentUser, persistUser: persistUser, completion: completion)
            case .failure:
                //TODO
                break
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
                completion(.success(user: currentUser))
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
