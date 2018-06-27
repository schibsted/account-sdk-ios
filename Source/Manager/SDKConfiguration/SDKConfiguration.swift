//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 This is a customization point for the way the SDK behaves internally for some cases. Only mess around in here if
 you know what you're doing.

 This is a singleton and is threadsafe.
 */
public class SDKConfiguration {
    /// Shared instance
    public static let shared = SDKConfiguration()
    init() {}

    private let queue = DispatchQueue(label: "com.schibsted.identity.UserSettings")

    /// Set or get `UserSettings.AgreementsCache` related settings data
    public var agreementsCache: AgreementsCache {
        get {
            return self.queue.sync {
                self._agreementsCache
            }
        }
        set(newValue) {
            self.queue.sync {
                self._agreementsCache = newValue
            }
        }
    }
    private var _agreementsCache = AgreementsCache.default

    func reset() {
        self.agreementsCache = .default
    }
}
