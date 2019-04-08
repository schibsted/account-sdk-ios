//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

protocol Storage {
    func setValue(_ value: Any?, forKey key: String)
    func value(forKey key: String) -> Any?
    func removeObject(forKey key: String)
    var keys: [String] { get }
}

extension UserDefaults: Storage {
    var keys: [String] {
        return Array(self.dictionaryRepresentation().keys)
    }
}
