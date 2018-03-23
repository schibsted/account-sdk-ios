//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension User {
    /**
     Gives you access to user profile related information
     */
    public class Profile: UserProfileAPI {
        weak var user: UserProtocol?

        /**
         Retrieve the user profile data.

         - parameter completion: a callback that receives the UserProfile or an error.
         */
        @discardableResult
        public func fetch(completion: @escaping (Result<UserProfile, ClientError>) -> Void) -> TaskHandle {
            guard let user = self.user as? User else {
                completion(.failure(.invalidUser))
                return NoopTaskHandle()
            }
            return user.taskManager.add(
                task: FetchUserProfileTask(user: user),
                completion: completion
            )
        }

        /**
         Update the user profile data.

         - parameter completion: a callback that's called on completion and might receive an error.
         */
        @discardableResult
        public func update(_ profile: UserProfile, completion: @escaping NoValueCallback) -> TaskHandle {
            guard let user = self.user as? User else {
                completion(.failure(.invalidUser))
                return NoopTaskHandle()
            }
            return user.taskManager.add(
                task: UpdateUserProfileTask(user: user, profile: profile),
                completion: completion
            )
        }

        /**
         Fetches the list of required fields that the user has not filled out yet

         - parameter completion: a callback that's called on completion and might receive an error.
         */
        @discardableResult
        public func requiredFields(completion: @escaping RequiredFieldsResultCallback) -> TaskHandle {
            guard let user = self.user as? User else {
                completion(.failure(.invalidUser))
                return NoopTaskHandle()
            }
            return user.taskManager.add(
                task: FetchRequiredFieldsTask(user: user),
                completion: completion
            )
        }
    }
}
