//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

///
public protocol IdentityManagerProtocol: class {
    ///
    var delegate: IdentityManagerDelegate? { get set }

    ///
    var clientConfiguration: ClientConfiguration { get }

    ///
    var routes: WebSessionRoutes { get }

    ///
    func sendCode(to identifier: Identifier, completion: @escaping NoValueCallback)
    ///
    func resendCode(to identifier: Identifier, completion: @escaping NoValueCallback)
    ///
    func validate(oneTimeCode: String, scopes: [String], persistUser: Bool, completion: @escaping NoValueCallback)
    ///
    func validate(oneTimeCode: String, for _: Identifier, scopes: [String], persistUser: Bool, completion: @escaping NoValueCallback)

    ///
    func login(username: Identifier, password: String, scopes: [String], persistUser: Bool, completion: @escaping NoValueCallback)

    ///
    func signup(
        username: Identifier,
        password: String,
        profile: UserProfile?,
        acceptTerms: Bool?,
        redirectPath: String?,
        persistUser: Bool,
        completion: @escaping NoValueCallback
    )
    ///
    func validate(authCode: String, persistUser: Bool, completion: @escaping NoValueCallback)

    ///
    func fetchStatus(for identifier: Identifier, completion: @escaping IdentifierStatusResultCallback)
    ///
    func fetchTerms(completion: @escaping TermsResultCallback)
}
