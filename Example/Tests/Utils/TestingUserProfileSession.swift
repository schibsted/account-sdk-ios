//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
@testable import SchibstedAccount

class TestingUserProfileSession: UserProfileSession {

    @discardableResult
    override func fetchProfile(
        completionCallback: @escaping (Result<UserProfile, ClientError>) -> Void
    ) -> TaskHandle {
        var handle: TaskHandle?
        Utils.waitUntilDone(completionCallback) {
            handle = super.fetchProfile(completionCallback: $0)
        }
        return handle!
    }

    @discardableResult
    override func updateProfile(
        _ profile: UserProfile,
        completionCallback: @escaping NoValueCallback
    ) -> TaskHandle {
        var handle: TaskHandle?
        Utils.waitUntilDone(completionCallback) {
            handle = super.updateProfile(profile, completionCallback: $0)
        }
        return handle!
    }
}
