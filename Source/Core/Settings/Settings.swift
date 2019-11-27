//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

struct Settings {
    static var proxy: SettingsProxy = DefaultSettingsProxy()
    static func setValue(_ value: Any?, forKey key: String) {
        proxy.setValue(value, forKey: key)
    }
    static func value(forKey key: String) -> Any? {
        return proxy.value(forKey: key)
    }
    static func clearAll() {
        proxy.clearAll()
    }
    static func clearWhere(prefix: String) {
        proxy.clearWhere(prefix: prefix)
    }
}
