//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
@testable import SchibstedAccount

class TestingIdentityManagerDelegate: IdentityManagerDelegate {
    var recordedState: UserState?
    func userStateChanged(_ state: UserState) {
        self.recordedState = state
    }
}

class TestingIdentityManager: IdentityManagerProtocol {
    var routes: WebSessionRoutes {
        return self.identityManager.routes
    }

    let identityManager: IdentityManager

    init(_ identityManager: IdentityManager) {
        self.identityManager = identityManager
    }

    weak var delegate: IdentityManagerDelegate? {
        get { return self.identityManager.delegate }
        set { self.identityManager.delegate = newValue }
    }

    var currentUser: User { return self.identityManager.currentUser }
    var clientConfiguration: ClientConfiguration { return self.identityManager.clientConfiguration }

    func sendCode(to identifier: Identifier, completion: @escaping NoValueCallback) {
        Utils.waitUntilDone(completion) { [unowned self] in
            self.identityManager.sendCode(to: identifier, completion: $0)
        }
    }

    func validate(oneTimeCode: String, scopes: [String] = [], persistUser: Bool, completion: @escaping NoValueCallback) {
        Utils.waitUntilDone(completion) { [unowned self] in
            self.identityManager.validate(oneTimeCode: oneTimeCode, scopes: scopes, persistUser: persistUser, completion: $0)
        }
    }

    func validate(oneTimeCode: String, for identifier: Identifier, scopes: [String] = [], persistUser: Bool, completion: @escaping NoValueCallback) {
        Utils.waitUntilDone(completion) { [unowned self] in
            self.identityManager.validate(oneTimeCode: oneTimeCode, for: identifier, scopes: scopes, persistUser: persistUser, completion: $0)
        }
    }

    func validate(authCode: String, persistUser: Bool, completion: @escaping NoValueCallback) {
        Utils.waitUntilDone(completion) { [unowned self] in
            self.identityManager.validate(authCode: authCode, persistUser: persistUser, completion: $0)
        }
    }

    func resendCode(to identifier: Identifier, completion: @escaping NoValueCallback) {
        Utils.waitUntilDone(completion) { [unowned self] in
            self.identityManager.resendCode(to: identifier, completion: $0)
        }
    }

    func login(username: Identifier, password: String, scopes: [String] = [], persistUser: Bool, completion: @escaping NoValueCallback) {
        Utils.waitUntilDone(completion) { [unowned self] in
            self.identityManager.login(username: username, password: password, scopes: scopes, persistUser: persistUser, completion: $0)
        }
    }

    func signup(
        username: Identifier,
        password: String,
        profile: UserProfile? = nil,
        acceptTerms: Bool? = nil,
        redirectPath: String? = nil,
        persistUser: Bool,
        completion: @escaping NoValueCallback
    ) {
        Utils.waitUntilDone(completion) { [unowned self] in
            self.identityManager.signup(
                username: username,
                password: password,
                profile: profile,
                acceptTerms: acceptTerms,
                redirectPath: redirectPath,
                persistUser: persistUser,
                completion: $0
            )
        }
    }

    func fetchStatus(for identifier: Identifier, completion: @escaping IdentifierStatusResultCallback) {
        Utils.waitUntilDone(completion) { [unowned self] in
            self.identityManager.fetchStatus(for: identifier, completion: $0)
        }
    }

    func fetchTerms(completion: @escaping TermsResultCallback) {
        Utils.waitUntilDone(completion) { [unowned self] in
            self.identityManager.fetchTerms(completion: $0)
        }
    }
}
