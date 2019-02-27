//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit
import LocalAuthentication

class PasswordCoordinator: AuthenticationCoordinator, RouteHandler {
    private let signinInteractor: SigninInteractor

    override init(navigationController: UINavigationController, identityManager: IdentityManager, configuration: IdentityUIConfiguration) {
        self.signinInteractor = SigninInteractor(identityManager: identityManager)
        super.init(navigationController: navigationController, identityManager: identityManager, configuration: configuration)
    }

    override func start(input: Input, completion: @escaping (Output) -> Void) {
        let viewModel = PasswordViewModel(
            identifier: input.identifier,
            loginFlowVariant: input.loginFlowVariant,
            localizationBundle: self.configuration.localizationBundle
        )
        // Are we allowed/able to use biometric login?
        let context = LAContext()
        guard configuration.useBiometrics, #available(iOS 11.3, *), context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            self.showPasswordView(for: input.identifier, on: input.loginFlowVariant, scopes: input.scopes, completion: completion)
            return
        }

        guard let password = self.getPasswordFromKeychain(for: input.identifier) else {
            self.showPasswordView(for: input.identifier, on: input.loginFlowVariant, scopes: input.scopes, completion: completion)
            return
        }

        let localizedReasonString = viewModel.biometricsPrompt + input.identifier.normalizedString

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReasonString) { success, _ in
            DispatchQueue.main.async {
                if success {
                    self.submit(password: password, for: input.identifier, on: input.loginFlowVariant, persistUser: true, scopes: input.scopes, completion: completion)
                } else {
                    self.showPasswordView(for: input.identifier, on: input.loginFlowVariant, scopes: input.scopes,  completion: completion)
                }
            }
        }
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
            case let .info(title: title, text: text):
                self?.presentInfo(title: title, text: text, titleImage: .schibstedRememberMeInfo)
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
                URLQueryItem(name: "scopes", value: scopes.joined(separator: " ")),
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
            self.spawnCompleteProfileCoordinator(for: .signup(identifier, password: password), persistUser: persistUser, completion: completion)
            return
        }

        self.presentedViewController?.startLoading()
        self.signinInteractor.login(username: identifier, password: password, scopes: scopes) { [weak self] result in
            self?.presentedViewController?.endLoading()

            switch result {
            case let .success(currentUser):
                self?.configuration.tracker?.loginID = currentUser.legacyID
                self?.updatekeyChain(for: identifier,loginFlowVariant: loginFlowVariant, password: password) {
                    self?.spawnCompleteProfileCoordinator(for: .signin(user: currentUser), persistUser: persistUser, completion: completion)
                }
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
        case signup(Identifier, password: String)
        case signin(user: User)
    }

    private func spawnCompleteProfileCoordinator(for variant: CompleteProfileVariant, persistUser: Bool, completion: @escaping (Output) -> Void) {
        let completeProfileInteractor: CompleteProfileInteractor

        switch variant {
        case let .signin(currentUser):
            completeProfileInteractor = UpdateProfileInteractor(currentUser: currentUser, loginFlowVariant: .signin, tracker: self.configuration.tracker)
        case let .signup(identifier, password):
            completeProfileInteractor = SignupInteractor(
                identifier: identifier,
                password: password,
                persistUser: persistUser,
                identityManager: self.identityManager
            )
        }

        let completeProfileCoordinator = CompleteProfileCoordinator(
            navigationController: self.navigationController,
            identityManager: self.identityManager,
            configuration: self.configuration
        )

        self.spawnChild(completeProfileCoordinator, input: completeProfileInteractor) { [weak self] output in
            switch output {
            case let .success(currentUser):
                switch variant {
                case .signin:
                    completion(.success(user: currentUser, persistUser: persistUser))
                case let .signup(identifier, _):
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
    private func getPasswordFromKeychain(for identifier: Identifier) -> String? {
        guard #available(iOS 11.3, *) else {
            // Fallback to passsword login
            return nil
        }
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecAttrAccount as String] = identifier.normalizedString as CFString
        query[kSecAttrLabel as String] = "com.schibsted.account.biometrics.secrets" as CFString
        query[kSecUseOperationPrompt as String] = "Please put your fingers on that button" as CFString

        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if status == noErr, let qresult =  queryResult as? Data {
            let password = String(data: qresult as Data, encoding: .utf8)!
            return password
        } else {
            return nil
        }
    }
    private func updatekeyChain(for identifier: Identifier, loginFlowVariant: LoginMethod.FlowVariant,  password: String, completion: @escaping () -> Void ) {
        if #available(iOS 11.3, *) {
            let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .userPresence, nil)
            var dictionary = [String: Any]()
            dictionary[kSecClass as String] = kSecClassGenericPassword
            dictionary[kSecAttrLabel as String] = "com.schibsted.account.biometrics.secrets" as CFString
            dictionary[kSecAttrAccount as String] = identifier.normalizedString as CFString
            dictionary[kSecValueData as String] = password.data(using: .utf8)! as CFData
            dictionary[kSecAttrAccessControl as String] = accessControl

            if let identityNotFirstLogin = Settings.value(forKey: "isNotFirstLogin") as? Bool, identityNotFirstLogin {
                if self.getPasswordFromKeychain(for: identifier) == nil && self.configuration.useBiometrics == true {
                    SecItemAdd(dictionary as CFDictionary, nil)
                }
                completion()
            } else {
                Settings.setValue(true, forKey: "isNotFirstLogin")
                let viewModel = PasswordViewModel(
                    identifier: identifier,
                    loginFlowVariant: loginFlowVariant,
                    localizationBundle: self.configuration.localizationBundle
                )
                let message = viewModel.biometricsOnboardingMessage.replacingOccurrences(of: "$0", with: configuration.appName)
                let alert = UIAlertController(title: viewModel.biometricsOnboardingTitle, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
                    self.configuration.enrollBiometrics(useBiometrics: true)
                    SecItemAdd(dictionary as CFDictionary, nil)
                    completion()
                })
                alert.addAction(UIAlertAction(title: "No", style: .default) { _ in
                    self.configuration.enrollBiometrics(useBiometrics: false)
                    completion()
                })

                self.navigationController.present(alert, animated: false)
            }
        }
    }
}
