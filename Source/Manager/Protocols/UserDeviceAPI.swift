//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

///
internal protocol UserDeviceAPI {
    ///
    @discardableResult
    func update(_ device: UserDevice, completion: @escaping NoValueCallback) -> TaskHandle
}
