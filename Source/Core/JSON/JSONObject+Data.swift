//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension JSONObjectProtocol where Key == String, Value == Any {
    func data() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }
}
