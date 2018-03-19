//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/// Handle that's returned by some calls. It can be used to cancel those calls
public protocol TaskHandle {
    ///
    func cancel()
}
