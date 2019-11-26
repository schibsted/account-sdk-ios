//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 This is a customization point for the way the SDK behaves internally for some cases. Only mess around in here if
 you know what you're doing.

 This is a singleton and is threadsafe.
 */
public class SDKConfiguration {
    /// Shared instance
    public static let shared = SDKConfiguration()
    init() {}

    private let queue = DispatchQueue(label: "com.schibsted.identity.UserSettings")

    /// Set or get `UserSettings.AgreementsCache` related settings data
    public var agreementsCache: AgreementsCache {
        get {
            return queue.sync {
                self._agreementsCache
            }
        }
        set(newValue) {
            queue.sync {
                self._agreementsCache = newValue
            }
        }
    }
    private var _agreementsCache = AgreementsCache.default

    func reset() {
        agreementsCache = .default
    }

    /**
     When you send out a request associated with a user access token and it returns with a 401, the `User` is refreshed and
     the request is refired with a new set of auth tokens. In the case that your request still comes back with a 401,
     even though the tokens were just refreshed and should be valid, an infinite loop can ensue. This variable controls
     how many times it should retry a request that previously came back with a 401. If the count is exceeded
     then you get back whatever the response and data was from the actual request, and the error will be
     `ClientError.RefreshRetryExceededCode` with the NSUnderlyingErrorKey set to actual request error (if there was one)

     - note default = 1
     */
    public var refreshRetryCount: Int? {
        get {
            let value = _refreshRetryCount.value
            return value == 0 ? nil : value
        }
        set(newValue) {
            _refreshRetryCount.value = newValue ?? 0
        }
    }
    private var _refreshRetryCount = AtomicInt(1)

    #if DEBUG
        /**
         Set this to debug access token and refreshing requests. If set to true then every successful request
         will also invalidate the access token so that a refresh will be forces

         Only settable in debug mode
         */
        public var invalidateteAuthTokenAfterSuccessfullRequest = false
    #else
        internal let invalidateteAuthTokenAfterSuccessfullRequest = false
    #endif
}
