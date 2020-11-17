//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import LocalAuthentication
import UIKit

private struct Constants {
    static let BiometricsSecretsLabel = "com.schibsted.account.biometrics.secrets"
    static let EmailStorageLabel = "com.schibsted.account.user.email"
}

class PasswordCoordinator: AuthenticationCoordinator, RouteHandler {
    private let signinInteractor: SigninInteractor

    @available(iOS 11.0, *)
    private var biometryType: LABiometryType {
        let context = LAContext()
        // `biometryType` property is only set after you call the canEvaluatePolicy(_:error:) method. The default value is LABiometryType.none.
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    override init(navigationController: UINavigationController, identityManager: IdentityManager, configuration: IdentityUIConfiguration) {
        signinInteractor = SigninInteractor(identityManager: identityManager)
        super.init(navigationController: navigationController, identityManager: identityManager, configuration: configuration)
    }

    override func start(input: Input, completion: @escaping (Output) -> Void) {
        let viewModel = PasswordViewModel(
            identifier: input.identifier,
            loginFlowVariant: input.loginFlowVariant,
            localizationBundle: configuration.localizationBundle
        )
        if !canUseBiometrics() || !configuration.useBiometrics {
            showPasswordView(for: input.identifier, on: input.loginFlowVariant, scopes: input.scopes, completion: completion)
            return
        }

        let localizedReasonString = viewModel.biometricsPrompt.replacingOccurrences(of: "$0", with: input.identifier.normalizedString)

        guard let password = getPasswordFromKeychain(for: input.identifier, localizedReasonString) else {
            showPasswordView(for: input.identifier, on: input.loginFlowVariant, scopes: input.scopes, completion: completion)
            return
        }

        let useSharedWebCredentials = configuration.useSharedWebCredentials

        submit(
            password: password,
            for: input.identifier,
            on: input.loginFlowVariant,
            persistUser: true,
            scopes: input.scopes,
            useSharedWebCredentials: useSharedWebCredentials,
            completion: completion
        )
    }

    func handle(route: IdentityUI.Route) -> RouteHandlerResult {
        switch route {
        case .login:
            if presentedViewController is CheckInboxViewController {
                // If the user confirmed the email after a login attempt, we take her back to the first screen of the flow where she can log in.
                return .resetRequest
            }
        case .enterPassword:
            let path = ClientConfiguration.RedirectInfo.ForgotPassword.path
            if isPresentingURL(containing: path) {
                // If the user changed her password after requesting a password change from the safari view, we close that view so that she can continue
                // with the login.

                // Dismiss the presented safari view (if any).
                dismissURLPresenting()
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
            localizationBundle: configuration.localizationBundle
        )
        let viewController = PasswordViewController(configuration: configuration, navigationSettings: navigationSettings, viewModel: viewModel)
        let useSharedWebCredentials = configuration.useSharedWebCredentials
        viewController.didRequestAction = { [weak self] action in
            switch action {
            case let .enter(password, shouldPersistUser):
                self?.submit(password: password, for: identifier, on: loginFlowVariant, persistUser: shouldPersistUser, scopes: scopes, useSharedWebCredentials: useSharedWebCredentials, completion: completion)
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

        navigationController.pushViewController(viewController, animated: true)
    }

    private func forgotPassword(for identifier: Identifier, scopes: [String]) {
        let localID = identifier.localID()
        let url = identityManager.routes.forgotPasswordURL(
            withRedirectPath: ClientConfiguration.RedirectInfo.ForgotPassword.path,
            redirectQueryItems: [
                URLQueryItem(name: "local_id", value: localID),
                URLQueryItem(name: "scopes", value: scopes.joined(separator: " ")),
            ]
        )
        present(url: url)
    }

    private func submit(
        password: String,
        for identifier: Identifier,
        on loginFlowVariant: LoginMethod.FlowVariant,
        persistUser: Bool,
        scopes: [String],
        useSharedWebCredentials: Bool,
        completion: @escaping (Output) -> Void
    ) {
        if loginFlowVariant == .signup {
            spawnCompleteProfileCoordinator(for: .signup(identifier, password: password), persistUser: persistUser, completion: completion)
            return
        }

        presentedViewController?.startLoading()
        signinInteractor.login(username: identifier, password: password, scopes: scopes, useSharedWebCredentials: useSharedWebCredentials) { [weak self] result in
            self?.presentedViewController?.endLoading()

            switch result {
            case let .success(currentUser):
                self?.configuration.tracker?.loginID = currentUser.legacyID
                if persistUser {
                    Settings.setValue(identifier.normalizedString, forKey: Constants.EmailStorageLabel)
                } else {
                    Settings.clearWhere(prefix: Constants.EmailStorageLabel)
                }
                self?.updatekeyChain(
                    for: identifier,
                    loginFlowVariant: loginFlowVariant,
                    password: password
                ) {
                    self?.spawnCompleteProfileCoordinator(for: .signin(user: currentUser), persistUser: persistUser, completion: completion)
                }
            case let .failure(error):
                self?.clearKeyChain(for: identifier)
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
            completeProfileInteractor = UpdateProfileInteractor(currentUser: currentUser, loginFlowVariant: .signin, tracker: configuration.tracker)
        case let .signup(identifier, password):
            completeProfileInteractor = SignupInteractor(
                identifier: identifier,
                password: password,
                persistUser: persistUser,
                identityManager: identityManager
            )
        }

        let completeProfileCoordinator = CompleteProfileCoordinator(
            navigationController: navigationController,
            identityManager: identityManager,
            configuration: configuration
        )

        spawnChild(completeProfileCoordinator, input: completeProfileInteractor) { [weak self] output in
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
        let viewModel = CheckInboxViewModel(identifier: identifier, localizationBundle: configuration.localizationBundle)
        let viewController = CheckInboxViewController(configuration: configuration, navigationSettings: navigationSettings, viewModel: viewModel)
        viewController.didRequestAction = { action in
            switch action {
            case .changeIdentifier:
                completion(.changeIdentifier)
            case .cancel:
                completion(.cancel)
            }
        }
        navigationController.pushViewController(viewController, animated: true)
    }
    private func getPasswordFromKeychain(for identifier: Identifier, _ localizedReasonString: String) -> String? {
        guard #available(iOS 11.3, *) else {
            // Fallback to passsword login
            return nil
        }
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecAttrAccount as String] = identifier.normalizedString as CFString
        query[kSecAttrLabel as String] = Constants.BiometricsSecretsLabel as CFString
        query[kSecUseOperationPrompt as String] = localizedReasonString as CFString

        var queryResult: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &queryResult)
        if status == noErr, let qresult = queryResult as? Data, let password = String(data: qresult as Data, encoding: .utf8) {
            configuration.tracker?.interaction(.submit, with: .passwordInput, additionalFields: [.customLoginType(biometryType)])
            return password
        } else {
            return nil
        }
    }

    private func canUseBiometrics() -> Bool {
        let context = LAContext()
        guard #available(iOS 11.3, *),
            configuration.enableBiometrics,
            context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil),
            context.biometryType == .touchID || context.biometryType == .faceID
        else {
            return false
        }
        return true
    }

    private func clearKeyChain(for identifier: Identifier) {
        if canUseBiometrics() {
            var query = [String: Any]()
            query[kSecClass as String] = kSecClassGenericPassword
            query[kSecReturnData as String] = kCFBooleanFalse
            query[kSecAttrAccount as String] = identifier.normalizedString as CFString
            query[kSecAttrLabel as String] = Constants.BiometricsSecretsLabel as CFString

            SecItemDelete(query as CFDictionary)
            return
        }
    }

    private func updatekeyChain(
        for identifier: Identifier,
        loginFlowVariant: LoginMethod.FlowVariant,
        password: String,
        completion: @escaping () -> Void
    ) {
        if !canUseBiometrics() {
            completion()
            return
        }
        guard #available(iOS 11.3, *),
            let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .biometryCurrentSet,
                nil
            ) else {
            return
        }
        var dictionary = [String: Any]()
        dictionary[kSecClass as String] = kSecClassGenericPassword
        dictionary[kSecAttrLabel as String] = Constants.BiometricsSecretsLabel as CFString
        dictionary[kSecAttrAccount as String] = identifier.normalizedString as CFString
        dictionary[kSecValueData as String] = password.data(using: .utf8)! as CFData
        dictionary[kSecAttrAccessControl as String] = accessControl

        let hasLoggedInBeforeSettingsKey = "hasLoggedInBefore"
        if let hasLoggedInBefore = Settings.value(forKey: hasLoggedInBeforeSettingsKey) as? Bool, hasLoggedInBefore {
            if configuration.useBiometrics {
                SecItemAdd(dictionary as CFDictionary, nil)
            }
            completion()
        } else {
            Settings.setValue(true, forKey: hasLoggedInBeforeSettingsKey)
            if biometryType == .touchID {
                let viewModel = PasswordViewModel(
                    identifier: identifier,
                    loginFlowVariant: loginFlowVariant,
                    localizationBundle: configuration.localizationBundle
                )
                let message = viewModel.touchIdOnboardingMessage
                    .replacingOccurrences(of: "$0", with: configuration.appName)
                let title = viewModel.touchIdOnboardingTitle

                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: viewModel.touchIdOnboardingAccept, style: .default) { _ in
                    self.configuration.useBiometrics(true)
                    SecItemAdd(dictionary as CFDictionary, nil)
                    completion()
                })
                alert.addAction(UIAlertAction(title: viewModel.touchIdOnboardingRefuse, style: .cancel) { _ in
                    self.configuration.useBiometrics(false)
                    completion()
                })

                navigationController.present(alert, animated: false)
            } else {
                configuration.useBiometrics(true)
                SecItemAdd(dictionary as CFDictionary, nil)
                completion()
            }
        }
    }
}
