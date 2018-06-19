//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class CompleteProfileCoordinator: FlowCoordinator {
    enum Output {
        case success(User)
        case cancel
        case back
        case reset
        case error(ClientError)
    }

    let navigationController: UINavigationController
    let identityManager: IdentityManager
    let configuration: IdentityUIConfiguration

    var child: ChildFlowCoordinator?

    private let termsInteractor: TermsInteractor
    private var userTermsInteractor: UserTermsInteractor?
    private let requiredFieldsInteractor: RequiredFieldsInteractor

    init(
        navigationController: UINavigationController,
        identityManager: IdentityManager,
        configuration: IdentityUIConfiguration
    ) {
        self.navigationController = navigationController
        self.identityManager = identityManager
        self.configuration = configuration
        self.termsInteractor = TermsInteractor(identityManager: identityManager)
        self.requiredFieldsInteractor = RequiredFieldsInteractor(identityManager: identityManager)
    }

    func start(input completeProfileInteractor: CompleteProfileInteractor, completion: @escaping (Output) -> Void) {
        let currentUser = completeProfileInteractor.currentUser
        let loginFlowVariant = completeProfileInteractor.loginFlowVariant

        self.ensureAgreementsAccepted(for: currentUser, on: loginFlowVariant) { [weak self] result in
            switch result {
            case .wereAlreadyAccepted:
                self?.ensureRequiredFieldsEntered(for: currentUser, on: loginFlowVariant) { [weak self] result in
                    self?.handleResult(
                        wereAgreementsJustAccepted: false,
                        requiredFieldEnteringResult: result,
                        completeProfileInteractor: completeProfileInteractor,
                        completion: completion
                    )
                }
            case .wereJustAccepted:
                self?.ensureRequiredFieldsEntered(for: currentUser, on: loginFlowVariant) { [weak self] result in
                    self?.handleResult(
                        wereAgreementsJustAccepted: true,
                        requiredFieldEnteringResult: result,
                        completeProfileInteractor: completeProfileInteractor,
                        completion: completion
                    )
                }
            case let .error(error):
                if self?.handle(error: error) != true { completion(.error(error)) }
            case .cancel:
                completion(.cancel)
            case .back:
                completion(.back)
            case .reset:
                completion(.reset)
            }
        }
    }

    private func handleResult(
        wereAgreementsJustAccepted: Bool,
        requiredFieldEnteringResult: RequiredFieldEnteringResult,
        completeProfileInteractor: CompleteProfileInteractor,
        completion: @escaping (Output) -> Void
    ) {
        switch requiredFieldEnteringResult {
        case let .updatedRequiredFields(fields):
            self.presentedViewController?.startLoading()
            completeProfileInteractor.completeProfile(acceptingTerms: wereAgreementsJustAccepted, requiredFieldsToUpdate: fields) { [weak self] result in
                self?.presentedViewController?.endLoading()
                switch result {
                case let .success(user):
                    completion(.success(user))
                case let .failure(error):
                    if self?.handle(error: error) != true { completion(.error(error)) }
                }
            }
        case .cancel:
            completion(.cancel)
        case let .error(error):
            if !self.handle(error: error) { completion(.error(error)) }
        }
    }
}

extension CompleteProfileCoordinator {
    private enum AgreementsAcceptanceResult {
        case wereAlreadyAccepted
        case wereJustAccepted
        case error(ClientError)
        case cancel
        case back
        case reset
    }

    private func ensureAgreementsAccepted(
        for currentUser: User?,
        on loginFlowVariant: LoginMethod.FlowVariant,
        completion: @escaping (AgreementsAcceptanceResult) -> Void
    ) {
        self.fetchAgreementsAcceptanceStatus(for: currentUser, on: loginFlowVariant) { [weak self] result in
            switch result {
            case .alreadyAccepted:
                // Agreements were already accepted, so there is no change in status.
                completion(.wereAlreadyAccepted)
            case .needAcceptance:
                // Agreements are not accepted, let the user accept them.
                self?.acceptAgreements(on: loginFlowVariant, completion: completion)
            case let .error(error):
                if self?.handle(error: error) != true { completion(.error(error)) }
            }
        }
    }

    private enum AgreementsAcceptanceStatus {
        case needAcceptance
        case alreadyAccepted
        case error(ClientError)
    }

    private func fetchAgreementsAcceptanceStatus(
        for currentUser: User?,
        on loginFlowVariant: LoginMethod.FlowVariant,
        completion: @escaping (AgreementsAcceptanceStatus) -> Void
    ) {
        if loginFlowVariant == .signin, let currentUser = currentUser {
            self.presentedViewController?.startLoading()

            self.userTermsInteractor = UserTermsInteractor(user: currentUser)
            self.userTermsInteractor?.fetchStatus { [weak self] result in
                self?.presentedViewController?.endLoading()

                switch result {
                case let .success(accepted):
                    completion(accepted ? .alreadyAccepted : .needAcceptance)
                case let .failure(error):
                    if self?.handle(error: error) != true { completion(.error(error)) }
                }
            }
        } else {
            // User always needs to accept agreements on signup.
            completion(.needAcceptance)
        }
    }

    private func acceptAgreements(on loginFlowVariant: LoginMethod.FlowVariant, completion: @escaping (AgreementsAcceptanceResult) -> Void) {
        self.presentedViewController?.startLoading()

        self.termsInteractor.fetchTerms { [weak self] result in
            self?.presentedViewController?.endLoading()

            switch result {
            case let .success(terms):
                self?.spawnShowTermsCoordinator(for: terms, on: loginFlowVariant, completion: completion)
            case let .failure(error):
                if self?.handle(error: error) != true { completion(.error(error)) }
            }
        }
    }

    private func spawnShowTermsCoordinator(
        for terms: Terms,
        on loginFlowVariant: LoginMethod.FlowVariant,
        completion: @escaping (AgreementsAcceptanceResult) -> Void
    ) {
        let showTermsCoordinator = ShowTermsCoordinator(navigationController: self.navigationController, configuration: self.configuration)
        let input = ShowTermsCoordinator.Input(terms: terms, loginFlowVariant: loginFlowVariant)

        self.spawnChild(showTermsCoordinator, input: input) { output in
            switch output {
            case .success:
                completion(.wereJustAccepted)
            case .cancel:
                completion(.cancel)
            case .back:
                completion(.back)
            }
        }
    }
}

extension CompleteProfileCoordinator {
    enum RequiredFieldEnteringResult {
        case updatedRequiredFields([SupportedRequiredField: String])
        case cancel
        case error(ClientError)
    }

    private func ensureRequiredFieldsEntered(
        for currentUser: User?,
        on loginFlowVariant: LoginMethod.FlowVariant,
        completion: @escaping (RequiredFieldEnteringResult) -> Void
    ) {
        self.presentedViewController?.startLoading()

        if loginFlowVariant == .signin, let currentUser = currentUser {
            self.requiredFieldsInteractor.fetchRequiredFields(for: currentUser) { [weak self] result in
                self?.presentedViewController?.endLoading()
                self?.handleFetchRequiredFieldsResult(result, completion: completion)
            }
        } else {
            self.requiredFieldsInteractor.fetchClientRequiredFields { [weak self] result in
                self?.presentedViewController?.endLoading()
                self?.handleFetchRequiredFieldsResult(result, completion: completion)
            }
        }
    }

    private func handleFetchRequiredFieldsResult(
        _ result: SchibstedAccount.Result<[RequiredField], ClientError>,
        completion: @escaping (RequiredFieldEnteringResult) -> Void
    ) {
        switch result {
        case let .success(requiredFields):
            let userMissesRequiredFields = SupportedRequiredField.from(requiredFields).count > 0
            if userMissesRequiredFields {
                // Let the user enter required fields.
                self.showEnterRequiredFieldsView(requiredFields, completion: completion)
            } else {
                // No required field was missing, thus no one was updated.
                completion(.updatedRequiredFields([:]))
            }
        case let .failure(error):
            if !self.handle(error: error) { completion(.error(error)) }
        }
    }

    private func showEnterRequiredFieldsView(_ requiredFields: [RequiredField], completion: @escaping (RequiredFieldEnteringResult) -> Void) {
        let navigationSettings = NavigationSettings(
            cancel: configuration.isCancelable ? { completion(.cancel) } : nil
        )
        let viewModel = RequiredFieldsViewModel(
            requiredFields: requiredFields,
            localizationBundle: self.configuration.localizationBundle,
            locale: self.identityManager.clientConfiguration.locale
        )
        let viewController = RequiredFieldsViewController(configuration: self.configuration, navigationSettings: navigationSettings, viewModel: viewModel)
        viewController.didRequestAction = { [weak self] action in
            switch action {
            case let .update(fields):
                completion(.updatedRequiredFields(fields))
            case .cancel:
                completion(.cancel)
            case let .open(url):
                self?.present(url: url)
            }
        }
        self.navigationController.pushViewController(viewController, animated: true)
    }
}

extension CompleteProfileCoordinator {
    private func handle(error: ClientError) -> Bool {
        if self.presentedViewController is TermsViewController || self.presentedViewController is RequiredFieldsViewController {
            self.present(error: error)
            return true
        }
        return false
    }
}
