//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension User {
    /**
     Contains APIs that allow you get access to tokens and control some oauth related settings for a user
     */
    public class Auth: UserAuthAPI {
        weak var user: UserProtocol?

        /**
         Get a one-time API authentication code for the current user.

         This code can be sent to a different API, or a different SDK (for example a JS SDK),
         and then exchanged for a new access token, which has the same powers the current access token.
         You must be in the logged in state to be able to call this method.
         See also a diagram for exchange type "code" on https://techdocs.login.schibsted.com/endpoints/POST/oauth/exchange/

         - parameter clientID: which client to get the code on behalf of
         - parameter completion: a callback that receives the code or an error.
         */
        @discardableResult
        public func oneTimeCode(clientID: String, completion: @escaping StringResultCallback) -> TaskHandle {
            return tokenExchange(clientID: clientID, type: .code, redirectURL: nil, completion: completion)
        }

        /**
         Get an URL with embedded one-time code for creating a web session for the current user.

         Suppose that you have a mobile native login UI,
         but want to have a web view, where the user is logged in as if he has logged in via a web login form.
         The URL returned by this method should be used to navigate the web view,
         which will then redirect to your destination given "redirectURL".
         After that happens you'll have a session cookie for the current user set up in the web view.
         That makes it possible to navigate to personalised or protected web pages in the logged in state.

         You must be in the logged in state to be able to call this method.
         See also a diagram for exchange type "session" on https://techdocs.login.schibsted.com/endpoints/POST/oauth/exchange/

         - parameter clientID: which client to get the code on behalf of
         - parameter redirectURL: where to redirect a web view at the cookie is set.
         - parameter completion: a callback that receives the code or an error.
         */
        @discardableResult
        public func webSessionURL(clientID: String, redirectURL: URL, completion: @escaping URLResultCallback) -> TaskHandle {
            guard let user = self.user as? User else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidUser))
                }
                return NoopTaskHandle()
            }

            let serverURL = user.clientConfiguration.serverURL
            return tokenExchange(clientID: clientID, type: .session, redirectURL: redirectURL) { result in
                switch result {
                case let .success(code):
                    DispatchQueue.main.async {
                        completion(.success(serverURL.appendingPathComponent("session/\(code)")))
                    }
                case let .failure(error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }

        private func tokenExchange(
            clientID: String,
            type: TokenExchangeType,
            redirectURL: URL?,
            completion: @escaping StringResultCallback
        ) -> TaskHandle {
            guard let user = self.user as? User else {
                completion(.failure(.invalidUser))
                return NoopTaskHandle()
            }
            return user.taskManager.add(
                task: TokenExchangeTask(user: user, clientID: clientID, type: type, redirectURL: redirectURL),
                completion: completion
            )
        }
    }
}
