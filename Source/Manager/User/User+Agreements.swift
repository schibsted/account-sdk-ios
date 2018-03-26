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

         Since new terms and conditions may be issued at any time, you should call this method at the app's startup to check that the logged in user (if any)
         you have obtained from an instance of `IdentityManager` has accepted the latest terms. If the result provided from the completion callback is `false`,
         then you should then present a screen where the user can review and accept the updated terms.

         The recommended way of presenting the terms acceptance screen is by using the provided UI flows, thus by calling`IdentityUI.presentTerms(for:from:)`.
         It is important that you pass the same instance of `User` you previously obtained and stored, otherwise you won't get logout notifications for that
         user in case the user is logged out for not having accepted the new terms.

         If you are using the headless approach instead, you should then present your own UI and manually call `accept(:)`, if the user accepted the new terms,
         or `User.logout()`, if the user rejected them.

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

         If you use the recommended way of presenting the screen to accept the terms, i.e. if you the UI flows provided by `IdentityUI`, then you should *not*
         call this method manually, as it will be automatically called for you when the user accepts the new terms. You should only use this method if you are
         following the headless approach and implementing your own UI.

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
