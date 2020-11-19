//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

public extension User {
    /**
     Gives you access to user device related information
     */
    class Device: UserDeviceAPI {
        weak var user: UserProtocol?

        /**
         Update the user device data, creating a new device fingerprint.

         - parameter completion: a callback that's called on completion and might receive an error.
         */
        @discardableResult
        public func update(_ device: UserDevice, completion: @escaping NoValueCallback) -> TaskHandle {
            guard let user = self.user as? User else {
                completion(.failure(.invalidUser))
                return NoopTaskHandle()
            }
            return user.taskManager.add(
                task: UpdateUserDeviceTask(user: user, device: device),
                completion: completion
            )
        }
    }
}
