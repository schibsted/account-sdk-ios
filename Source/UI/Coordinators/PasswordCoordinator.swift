//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class PasswordCoordinator: AuthenticationCoordinator, RouteHandler {
    private let signinInteractor: SigninInteractor

    override init(navigationController: UINavigationController, identityManager: IdentityManager, configuration: IdentityUIConfiguration) {
        self.signinInteractor = SigninInteractor(identityManager: identityManager)
        super.init(navigationController: navigationController, identityManager: identityManager, configuration: configuration)
    }

    override func start(input: Input, completion: @escaping (Output) -> Void) {
        self.showPasswordView(for: input.identifier, on: input.loginFlowVariant, scopes: input.scopes, completion: completion)
    }

    func handle(route: IdentityUI.Route) -> RouteHandlerResult {
        switch route {
        case .login:
            if self.presentedViewController is CheckInboxViewController {
                // If the user confirmed the email after a login attempt, we take her back to the first screen of the flow where she can log in.
                return .resetRequest
            }
        case .enterPassword:
            let path = ClientConfiguration.RedirectInfo.ForgotPassword.path
            if self.isPresentingURL(containing: path) {
                // If the user changed her password after requesting a password change from the safari view, we close that view so that she can continue
                // with the login.

                // Dismiss the presented safari view (if any).
                self.dismissURLPresenting()
            }
            return .handled
        case .validateAuthCode:
            break
        }

        return .cannotHandle
    }
}

extension PasswordCoordinator {
    private func showPasswordView(
        for identifier: Identifier,
        on loginFlowVariant: LoginMethod.FlowVariant,
        scopes: [String],
        completion: @escaping (Output) -> Void
    ) {
        let navigationSettings = NavigationSettings(
            cancel: configuration.isCancelable ? { completion(.cancel) } : nil,
            back: { completion(.back) }
        )
        let viewModel = PasswordViewModel(
            identifier: identifier,
            loginFlowVariant: loginFlowVariant,
            localizationBundle: self.configuration.localizationBundle
        )
        let viewController = PasswordViewController(configuration: self.configuration, navigationSettings: navigationSettings, viewModel: viewModel)

        viewController.didRequestAction = { [weak self] action in
            switch action {
            case let .enter(password, shouldPersistUser):
                self?.submit(password: password, for: identifier, on: loginFlowVariant, persistUser: shouldPersistUser, scopes: scopes, completion: completion)
            case .changeIdentifier:
                completion(.changeIdentifier)
            case .forgotPassword:
                self?.forgotPassword(for: identifier, scopes: scopes)
            case .back:
                completion(.back)
            case .cancel:
                completion(.cancel)
            }
        }

        self.navigationController.pushViewController(viewController, animated: true)
    }

    private func forgotPassword(for identifier: Identifier, scopes: [String]) {
        let localID = identifier.localID()
        let url = self.identityManager.routes.forgotPasswordURL(
            withRedirectPath: ClientConfiguration.RedirectInfo.ForgotPassword.path,
            redirectQueryItems: [
                URLQueryItem(name: "local_id", value: localID),
                URLQueryItem(name: "scopes", value: scopes.joined(separator: " "))
            ]
        )
        self.present(url: url)
    }

    private func submit(
        password: String,
        for identifier: Identifier,
        on loginFlowVariant: LoginMethod.FlowVariant,
        persistUser: Bool,
        scopes: [String],
        completion: @escaping (Output) -> Void
    ) {
        if loginFlowVariant == .signup {
            self.spawnCompleteProfileCoordinator(for: .signup(identifier, password: password, shouldPersistUser: persistUser), completion: completion)
            return
        }

        self.presentedViewController?.startLoading()
        self.signinInteractor.login(username: identifier, password: password, scopes: scopes, persistUser: persistUser) { [weak self] result in
            self?.presentedViewController?.endLoading()

            switch result {
            case let .success(currentUser):
                self?.configuration.tracker?.loginID = currentUser.id
                self?.spawnCompleteProfileCoordinator(for: .signin(currentUser), completion: completion)
            case let .failure(error):
                if self?.presentedViewController?.showInlineError(error) == true {
                    return
                }

                if case .unverifiedEmail = error {
                    self?.showCheckInboxView(for: identifier, completion: completion)
                } else {
                    self?.present(error: error)
                }
            }
        }
    }
}

extension PasswordCoordinator {
    enum CompleteProfileVariant {
        case signup(Identifier, password: String, shouldPersistUser: Bool)
        case signin(User)
    }

    private func spawnCompleteProfileCoordinator(for variant: CompleteProfileVariant, completion: @escaping (Output) -> Void) {
        let completeProfileInteractor: CompleteProfileInteractor

        switch variant {
        case let .signin(currentUser):
            completeProfileInteractor = UpdateProfileInteractor(currentUser: currentUser, loginFlowVariant: .signin, tracker: self.configuration.tracker)
        case let .signup(identifier, password, shouldPersistUser):
            completeProfileInteractor = SignupInteractor(
                identifier: identifier,
                password: password,
                persistUser: shouldPersistUser,
                identityManager: self.identityManager
            )
        }

        let completeProfileCoordinator = CompleteProfileCoordinator(
            navigationController: self.navigationController,
            identityManager: self.identityManager,
            configuration: self.configuration
        )

        self.child = ChildFlowCoordinator(completeProfileCoordinator, input: completeProfileInteractor) { [weak self] output in
            self?.child = nil

            switch output {
            case let .success(currentUser):
                switch variant {
                case .signin:
                    completion(.success(currentUser))
                case let .signup(identifier, _, _):
                    self?.showCheckInboxView(for: identifier, completion: completion)
                }
            case .cancel:
                completion(.cancel)
            case .back:
                self?.navigationController.popViewController(animated: true)
            case .reset:
                completion(.reset(nil))
            case let .error(error):
                self?.present(error: error)
            }
        }
    }
}

extension PasswordCoordinator {
    private func showCheckInboxView(for identifier: Identifier, completion: @escaping (Output) -> Void) {
        let navigationSettings = NavigationSettings(
            cancel: configuration.isCancelable ? { completion(.cancel) } : nil
        )
        let viewModel = CheckInboxViewModel(identifier: identifier, localizationBundle: self.configuration.localizationBundle)
        let viewController = CheckInboxViewController(configuration: self.configuration, navigationSettings: navigationSettings, viewModel: viewModel)
        viewController.didRequestAction = { action in
            switch action {
            case .changeIdentifier:
                completion(.changeIdentifier)
            case .cancel:
                completion(.cancel)
            }
        }
        self.navigationController.pushViewController(viewController, animated: true)
    }
}
