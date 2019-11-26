//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

protocol SettingsProxy {
    static var keyPrefix: String { get }
    var storage: Storage { get }
}

extension SettingsProxy {
    var storage: Storage {
        return Foundation.UserDefaults.standard
    }
    func setValue(_ value: Any?, forKey key: String) {
        storage.setValue(value, forKey: [type(of: self).keyPrefix, key].joined(separator: "."))
    }
    func value(forKey key: String) -> Any? {
        return storage.value(forKey: [type(of: self).keyPrefix, key].joined(separator: "."))
    }
    func clearAll() {
        for key in storage.keys where key.hasPrefix(type(of: self).keyPrefix) {
            self.storage.removeObject(forKey: key)
        }
    }
    func clearWhere(prefix subprefix: String) {
        let topLevelPrefixCount = type(of: self).keyPrefix.count
        for key in storage.keys {
            guard key.count >= topLevelPrefixCount + subprefix.count + 1 else {
                continue
            }
            let topLevelPrefixEndIndex = key.index(key.startIndex, offsetBy: topLevelPrefixCount + 1)
            if key[topLevelPrefixEndIndex...].hasPrefix(subprefix) {
                storage.removeObject(forKey: key)
            }
        }
    }
}
