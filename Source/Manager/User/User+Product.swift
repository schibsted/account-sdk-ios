//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension User {
    /**
     Gives you access to product related information for a user
     */
    public class Product: UserProductAPI {
        weak var user: UserProtocol?

        /**
         Retrieve the user product data.

         - parameter productID: which product to fetch information for
         - parameter completion: a callback that receives the UserProduct or an error.
         */
        @discardableResult
        public func fetch(productID: String, completion: @escaping (Result<UserProduct, ClientError>) -> Void) -> TaskHandle {
            guard let user = self.user as? User else {
                completion(.failure(.invalidUser))
                return NoopTaskHandle()
            }
            return user.taskManager.add(
                task: FetchUserProductTask(user: user, productID: productID),
                completion: completion
            )
        }
    }
}
