//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

///
public protocol UserProfileAPI {
    ///
    @discardableResult
    func fetch(completion: @escaping (Result<UserProfile, ClientError>) -> Void) -> TaskHandle
    ///
    @discardableResult
    func update(_ profile: UserProfile, completion: @escaping NoValueCallback) -> TaskHandle
    ///
    @discardableResult
    func requiredFields(completion: @escaping RequiredFieldsResultCallback) -> TaskHandle
}
