//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class AuthenticationCoordinator: FlowCoordinator {
    struct Input {
        let identifier: Identifier
        let loginFlowVariant: LoginMethod.FlowVariant
        let scopes: [String]
    }

    enum Output {
        case success(User)
        case cancel
        case back
        case changeIdentifier
        case reset(ClientError?)
        case error(ClientError?)
    }

    let navigationController: UINavigationController
    let identityManager: IdentityManager
    let configuration: IdentityUIConfiguration

    var child: ChildFlowCoordinator?

    init(navigationController: UINavigationController, identityManager: IdentityManager, configuration: IdentityUIConfiguration) {
        self.navigationController = navigationController
        self.identityManager = identityManager
        self.configuration = configuration
    }

    func start(input _: Input, completion _: @escaping (Output) -> Void) { preconditionFailure("Needs to be overridden in subclass") }
}
