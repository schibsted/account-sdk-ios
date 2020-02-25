//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

///
public protocol UserAgreementsAPI {
    ///
    @discardableResult
    func status(completion: @escaping BoolResultCallback) -> TaskHandle
    ///
    @discardableResult
    func accept(completion: @escaping NoValueCallback) -> TaskHandle
}
