//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

struct Settings {
    static var proxy: SettingsProxy = DefaultSettingsProxy()
    static func setValue(_ value: Any?, forKey key: String) {
        self.proxy.setValue(value, forKey: key)
    }
    static func value(forKey key: String) -> Any? {
        return self.proxy.value(forKey: key)
    }
    static func clearAll() {
        self.proxy.clearAll()
    }
    static func clearWhere(prefix: String) {
        self.proxy.clearWhere(prefix: prefix)
    }
}
