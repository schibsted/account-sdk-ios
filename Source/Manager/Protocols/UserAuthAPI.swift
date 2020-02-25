//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

///
public protocol UserAuthAPI: AnyObject {
    ///
    @discardableResult
    func oneTimeCode(clientID: String, completion: @escaping StringResultCallback) -> TaskHandle
    ///
    @discardableResult
    func webSessionURL(clientID: String, redirectURL: URL, completion: @escaping URLResultCallback) -> TaskHandle
}
