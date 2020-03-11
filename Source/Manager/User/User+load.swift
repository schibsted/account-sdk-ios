//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension User {
    /**
     Loads the last user that was persisted to the keychain
     */
    public static func loadLast(withConfiguration clientConfiguration: ClientConfiguration) -> User {
        let user = User(clientConfiguration: clientConfiguration)
        try? user.loadStoredTokens()
        return user
    }
}
