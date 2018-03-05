//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Convenience overloads for IdentityManager methods.
 */
public extension IdentityManagerProtocol {

    /// - SeeAlso: `IdentityManager.sendCode(...)`
    public func sendCode(to email: EmailAddress, completion: @escaping NoValueCallback) {
        return self.sendCode(to: Identifier(email), completion: completion)
    }

    /// - SeeAlso: `IdentityManager.sendCode(...)`
    public func sendCode(to phone: PhoneNumber, completion: @escaping NoValueCallback) {
        return self.sendCode(to: Identifier(phone), completion: completion)
    }

    /// - SeeAlso: `IdentityManager.resendCode(...)`
    public func resendCode(to email: EmailAddress, completion: @escaping NoValueCallback) {
        return self.resendCode(to: Identifier(email), completion: completion)
    }

    /// - SeeAlso: `IdentityManager.resendCode(...)`
    public func resendCode(to phone: PhoneNumber, completion: @escaping NoValueCallback) {
        return self.resendCode(to: Identifier(phone), completion: completion)
    }

    /// - SeeAlso: `IdentityManager.validate(oneTimeCode:for:completion:)`
    func validate(oneTimeCode: String, for email: EmailAddress, completion: @escaping NoValueCallback) {
        return self.validate(oneTimeCode: oneTimeCode, for: Identifier(email), completion: completion)
    }

    /// - SeeAlso: `IdentityManager.validate(oneTimeCode:for:completion:)`
    func validate(oneTimeCode: String, for phone: PhoneNumber, completion: @escaping NoValueCallback) {
        return self.validate(oneTimeCode: oneTimeCode, for: Identifier(phone), completion: completion)
    }

    /// - SeeAlso: `IdentityManager.login(...)`
    func login(email: EmailAddress, password: String, completion: @escaping NoValueCallback) {
        return self.login(username: Identifier(email), password: password, completion: completion)
    }
    /// - SeeAlso: `IdentityManager.signup(...)`
    func signup(email: EmailAddress, password: String, completion: @escaping NoValueCallback) {
        return self.signup(username: Identifier(email), password: password, profile: nil, acceptTerms: nil, redirectPath: nil, completion: completion)
    }

    /// - SeeAlso: `IdentityManager.fetchStatus(...)`
    func fetchStatus(for email: EmailAddress, completion: @escaping IdentifierStatusResultCallback) {
        return self.fetchStatus(for: Identifier(email), completion: completion)
    }

    /// - SeeAlso: `IdentityManager.fetchStatus(...)`
    func fetchStatus(for phone: PhoneNumber, completion: @escaping IdentifierStatusResultCallback) {
        return self.fetchStatus(for: Identifier(phone), completion: completion)
    }
}
