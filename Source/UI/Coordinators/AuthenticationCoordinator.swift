//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class AuthenticationCoordinator: FlowCoordinator {
    struct Input {
        let identifier: Identifier
        let loginFlowVariant: LoginMethod.FlowVariant
        let scopes: [String]
    }

    enum Output {
        case success(user: User, persistUser: Bool)
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
