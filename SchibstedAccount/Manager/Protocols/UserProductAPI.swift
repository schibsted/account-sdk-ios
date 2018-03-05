//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

///
public protocol UserProductAPI {
    ///
    @discardableResult
    func fetch(productID: String, completion: @escaping (Result<UserProduct, ClientError>) -> Void) -> TaskHandle
}
