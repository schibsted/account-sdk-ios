//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class PasswordlessCoordinator: AuthenticationCoordinator {
    private let oneTimeCodeInteractor: OneTimeCodeInteractor

    override init(navigationController: UINavigationController, identityManager: IdentityManager, configuration: IdentityUIConfiguration) {
        self.oneTimeCodeInteractor = OneTimeCodeInteractor(identityManager: identityManager)
        super.init(navigationController: navigationController, identityManager: identityManager, configuration: configuration)
    }

    override func start(input: Input, completion: @escaping (Output) -> Void) {
        self.sendCode(to: input.identifier) { [weak self] succeeded, error in
            guard succeeded else {
                completion(.error(error))
                return
            }
            self?.showVerifyView(for: input.identifier, on: input.loginFlowVariant, scopes: input.scopes, completion: completion)
        }
    }

    private func sendCode(to identifier: Identifier, completion: @escaping (_ succeeded: Bool, _ error: ClientError?) -> Void) {
        self.presentedViewController?.startLoading()

        self.oneTimeCodeInteractor.sendCode(to: identifier, completion: { [weak self] result in
            self?.presentedViewController?.endLoading()

            switch result {
            case .success:
                completion(true, nil)
            case let .failure(error):
                completion(false, error)
            }
        })
    }
}

extension PasswordlessCoordinator {
    private func showVerifyView(
        for identifier: Identifier,
        on loginFlowVariant: LoginMethod.FlowVariant,
        scopes: [String],
        completion: @escaping (Output) -> Void
    ) {
        let navigationSettings = NavigationSettings(
            cancel: configuration.isCancelable ? { completion(.cancel) } : nil,
            back: { completion(.changeIdentifier) }
        )
        let viewModel = VerifyViewModel(identifier: identifier, localizationBundle: self.configuration.localizationBundle)
        let viewController = VerifyViewController(configuration: self.configuration, navigationSettings: navigationSettings, viewModel: viewModel)
        viewController.didRequestAction = { [weak self] action in
            switch action {
            case let .enter(code, shouldPersistUser):
                self?.submit(code: code, for: identifier, on: loginFlowVariant, scopes: scopes, persistUser: shouldPersistUser, completion: completion)
            case .resendCode:
                self?.resendCode(for: identifier, completion: completion)
            case .changeIdentifier:
                completion(.changeIdentifier)
            case .cancel:
                completion(.cancel)
            case let .info(title, text):
                self?.presentInfo(title: title, text: text, titleImage: .schibstedRememberMeInfo)
            }
        }
        self.navigationController.pushViewController(viewController, animated: true)
    }
}

extension PasswordlessCoordinator {
    private func submit(
        code: String,
        for identifier: Identifier,
        on loginFlowVariant: LoginMethod.FlowVariant,
        scopes: [String],
        persistUser: Bool,
        completion: @escaping (Output) -> Void
    ) {
        self.presentedViewController?.startLoading()
        self.oneTimeCodeInteractor.validate(oneTimeCode: code, for: identifier, scopes: scopes) { [weak self] result in
            self?.presentedViewController?.endLoading()
            switch result {
            case let .success(currentUser):
                self?.configuration.tracker?.loginID = currentUser.legacyID
                self?.spawnCompleteProfileCoordinator(for: currentUser, on: loginFlowVariant, persistUser: persistUser, completion: completion)
            case let .failure(error):
                if self?.presentedViewController?.showInlineError(error) == true {
                    return
                }
                self?.present(error: error)
            }
        }
    }

    private func spawnCompleteProfileCoordinator(
        for currentUser: User,
        on loginFlowVariant: LoginMethod.FlowVariant,
        persistUser: Bool,
        completion: @escaping (Output) -> Void
    ) {
        let ensureProfileDataCoordinator = CompleteProfileCoordinator(
            navigationController: self.navigationController,
            identityManager: self.identityManager,
            configuration: self.configuration
        )

        let updateProfileInteractor = UpdateProfileInteractor(currentUser: currentUser, loginFlowVariant: loginFlowVariant, tracker: self.configuration.tracker)
        self.spawnChild(ensureProfileDataCoordinator, input: updateProfileInteractor) { output in
            switch output {
            case let .success(currentUser):
                completion(.success(user: currentUser, persistUser: persistUser))
            case .cancel:
                completion(.cancel)
            case .back, .reset:
                // `.back` also falls here, since it makes no sense to go back to the verify screen.
                completion(.reset(nil))
            case let .error(error):
                // We have to reset in case of error, since it makes no sense to stay in the verify screen after the code has been sent.
                completion(.reset(error))
            }
        }
    }
}

extension PasswordlessCoordinator {
    private func resendCode(for identifier: Identifier, completion: @escaping (Output) -> Void) {
        self.presentedViewController?.startLoading()
        self.oneTimeCodeInteractor.resendCode(to: identifier) { [weak self] result in
            self?.presentedViewController?.endLoading()

            switch result {
            case .success:
                self?.showResendView(with: identifier, completion: completion)
            case let .failure(error):
                self?.present(error: error)
            }
        }
    }

    private func showResendView(with identifier: Identifier, completion: @escaping (Output) -> Void) {
        let viewModel = ResendViewModel(identifier: identifier, localizationBundle: self.configuration.localizationBundle)
        let viewController = ResendViewController(configuration: self.configuration, viewModel: viewModel)
        viewController.didRequestAction = { action in
            switch action {
            case .changeIdentifier:
                completion(.changeIdentifier)
            }
        }
        self.presentAsPopup(viewController)
    }
}
