//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Provided for testing and mocking purposes. See `User` for field descriptions.
 */
public protocol UserProtocol: AnyObject {
    ///
    var delegate: UserDelegate? { get set }
    ///
    var id: String? { get }
    ///
    var profile: UserProfileAPI { get }
    ///
    var assets: UserAssetsAPI { get }
    ///
    var agreements: UserAgreementsAPI { get }
    ///
    var auth: UserAuthAPI { get }
    ///
    var state: UserState { get }
    ///
    func logout()
}
