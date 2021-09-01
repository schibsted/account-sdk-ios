//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

public extension User {
    /**
     Loads the last user that was persisted to the keychain
     */
    static func loadLast(withConfiguration clientConfiguration: ClientConfiguration) -> User {
        let user = User(clientConfiguration: clientConfiguration)
        try? user.loadStoredTokens()
        return user
    }
    /**
     Enables App transfer step 1
     */
    static func storeOnDevice(withConfiguration clientConfiguration: ClientConfiguration, storageKey: String) {
        let user = User(clientConfiguration: clientConfiguration)
        try? user.storeOnDevice(key: storageKey)
    }
    /**
     Enables App transfer step 2
     */
    static func loadFromDevice(withConfiguration clientConfiguration: ClientConfiguration, storageKey: String) -> User? {
        let user = User(clientConfiguration: clientConfiguration)
        try? user.loadFromDeviceToKeychain(key: storageKey)

        return user
    }
}
