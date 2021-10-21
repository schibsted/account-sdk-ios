//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/// `User` object delegate to be notified of changes
public protocol UserDelegate: AnyObject {
    /**
     Is notified when the state of the user changes
     */
    func user(_ user: User, didChangeStateTo newState: UserState)
    /**
     Is notified when the state of the user changes due to an error
     */
    func user(_ user: User, didChangeStateTo newState: UserState, error: ClientError)
}

public extension UserDelegate {
    func user(_ user: User, didChangeStateTo newState: UserState, error: ClientError) {
        self.user(user, didChangeStateTo: newState)
    }
}
