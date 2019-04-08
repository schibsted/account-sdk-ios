//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

extension User {
    /**
     Gives you access to asset related information for a user
     */
    public class Assets: UserAssetsAPI {
        weak var user: UserProtocol?

        /**
         Retrieve the user assets data.

         - parameter completion: a callback that receives the UserAssets or an error.
         */
        @discardableResult
        public func fetch(completion: @escaping UserAssetsResultCallback) -> TaskHandle {
            guard let user = self.user as? User else {
                completion(.failure(.invalidUser))
                return NoopTaskHandle()
            }
            return user.taskManager.add(
                task: FetchUserAssetsTask(user: user),
                completion: completion
            )
        }
    }
}
