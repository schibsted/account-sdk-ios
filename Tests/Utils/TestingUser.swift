//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Nimble
import Quick
@testable import SchibstedAccount

class TestingUserAuth: UserAuthAPI {
    let wrapped: User.Auth

    init(_ auth: User.Auth) {
        self.wrapped = auth
    }

    func oneTimeCode(clientID: String, completion: @escaping StringResultCallback) -> TaskHandle {
        return Utils.waitUntilDone(completion) { [unowned self] in
            self.wrapped.oneTimeCode(clientID: clientID, completion: $0)
        }
    }

    func webSessionURL(clientID: String, redirectURL: URL, completion: @escaping URLResultCallback) -> TaskHandle {
        return Utils.waitUntilDone(completion) { [unowned self] in
            self.wrapped.webSessionURL(clientID: clientID, redirectURL: redirectURL, completion: $0)
        }
    }
}

class TestingUserProfile: UserProfileAPI {
    let wrapped: User.Profile
    init(_ profile: User.Profile) {
        self.wrapped = profile
    }
    func fetch(completion: @escaping (Result<UserProfile, ClientError>) -> Void) -> TaskHandle {
        return Utils.waitUntilDone(completion) { [unowned self] in
            self.wrapped.fetch(completion: $0)
        }
    }

    func update(_ profile: UserProfile, completion: @escaping NoValueCallback) -> TaskHandle {
        return Utils.waitUntilDone(completion) { [unowned self] in
            self.wrapped.update(profile, completion: $0)
        }
    }

    func requiredFields(completion: @escaping (Result<[RequiredField], ClientError>) -> Void) -> TaskHandle {
        return Utils.waitUntilDone(completion) { [unowned self] in
            self.wrapped.requiredFields(completion: $0)
        }
    }
}

class TestingUserProduct: UserProductAPI {
    let wrapped: User.Product
    init(_ product: User.Product) {
        self.wrapped = product
    }
    func fetch(productID: String, completion: @escaping (Result<UserProduct, ClientError>) -> Void) -> TaskHandle {
        return Utils.waitUntilDone(completion) { [unowned self] in
            self.wrapped.fetch(productID: productID, completion: $0)
        }
    }
}

class TestingUserAssets: UserAssetsAPI {
    let wrapped: User.Assets
    init(_ assets: User.Assets) {
        self.wrapped = assets
    }
    func fetch(completion: @escaping UserAssetsResultCallback) -> TaskHandle {
        return Utils.waitUntilDone(completion) { [unowned self] in
            self.wrapped.fetch(completion: $0)
        }
    }
}

class TestingUserAgreements: UserAgreementsAPI {
    let wrapped: User.Agreements
    init(_ agreements: User.Agreements) {
        self.wrapped = agreements
    }
    func status(completion: @escaping BoolResultCallback) -> TaskHandle {
        return Utils.waitUntilDone(completion) { [unowned self] in
            self.wrapped.status(completion: $0)
        }
    }

    func accept(completion: @escaping NoValueCallback) -> TaskHandle {
        return Utils.waitUntilDone(completion) { [unowned self] in
            self.wrapped.accept(completion: $0)
        }
    }
}

class TestingUserDelegate: UserDelegate {
    var stateChangedData: [UserState] = []
    func user(_: User, didChangeStateTo state: UserState) {
        self.stateChangedData.append(state)
    }
}

class TestingUser: UserProtocol {

    var wrapped: User

    init(clientConfiguration: ClientConfiguration) {
        self.wrapped = User(clientConfiguration: clientConfiguration)
    }

    var profile: UserProfileAPI {
        return TestingUserProfile(self.wrapped.profile as! User.Profile)
    }

    var product: UserProductAPI {
        return TestingUserProduct(self.wrapped.product as! User.Product)
    }

    var assets: UserAssetsAPI {
        return TestingUserAssets(self.wrapped.assets as! User.Assets)
    }

    var agreements: UserAgreementsAPI {
        return TestingUserAgreements(self.wrapped.agreements as! User.Agreements)
    }

    var auth: UserAuthAPI {
        return TestingUserAuth(self.wrapped.auth as! User.Auth)
    }

    var delegate: UserDelegate? {
        get {
            return self.wrapped.delegate
        }
        set(delegate) {
            self.wrapped.delegate = delegate
        }
    }

    var state: UserState {
        return self.wrapped.state
    }

    var id: String? {
        return self.wrapped.id
    }

    func logout() {
        self.wrapped.logout()
    }

    func refresh(completion: @escaping NoValueCallback) {
        Utils.waitUntilDone(completion) { [unowned self] in
            self.wrapped.refresh(completion: $0)
        }
    }
}

extension URLSession {
    convenience init(user testingUser: TestingUser, configuration: URLSessionConfiguration) {
        self.init(user: testingUser.wrapped, configuration: configuration)
    }
}
