//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Possible states that this user is currently in.
 */
public enum UserState: Int, CustomStringConvertible {
    ///
    case loggedOut
    ///
    case loggedIn
    ///
    public var description: String {
        switch self {
        case .loggedOut:
            return "loggedOut"
        case .loggedIn:
            return "loggedIn"
        }
    }
}
