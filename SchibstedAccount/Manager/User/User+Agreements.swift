//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension User {
    /**
     Agreement related APIs that give you information about the status of this user's agreements acceptance.

     Agreements consists of terms and conditions and privacy policies. Acccepting agreements means the user
     has accepted all the agreements fetchable via `IdentityManager.fetchAgreements(...)`
     */
    public class Agreements: UserAgreementsAPI {
        weak var user: UserProtocol?

        /**
         Check if the latest terms & conditions agreements were accepted by the current user.

         - parameter completion: a callback that receives the status or an error.
         */
        @discardableResult
        public func status(completion: @escaping BoolResultCallback) -> TaskHandle {
            guard let user = user as? User else {
                completion(.failure(.invalidUser))
                return NoopTaskHandle()
            }
            return user.taskManager.add(
                task: FetchAgreementsStatusTask(user: user),
                completion: completion
            )
        }

        /**
         Accept the latest terms & conditions agreements on behalf of the current user.

         - parameter completion: a callback that's called on completion and might receive an error.
         */
        @discardableResult
        public func accept(completion: @escaping NoValueCallback) -> TaskHandle {
            guard let user = user as? User else {
                completion(.failure(.invalidUser))
                return NoopTaskHandle()
            }
            return user.taskManager.add(
                task: AcceptAgreementsTask(user: user),
                completion: completion
            )
        }
    }
}
