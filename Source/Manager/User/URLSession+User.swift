//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 The URLSession is exactly the same as the foundation API one, but it has been modified to act on a specific `User` object instead and
 to automatically manage OAuth related session lifetimes and renewals.

 If you want to make requests that contain the internal user access tokens, you should create a session object with one of the provided
 extension initializers. Following this, you may use the URLSession as you would any other session, the only difference is that all
 requests send with this session will contain a Authorization header with a bearer access token inside it.

 ### Automatic refreshing

 The URLSession sets a custom URLProtocol object internally that is used to managed all requests created with this session. Before
 forwarding the results of a request back to you, the protocol implementation checks to make sure that the HTTP status code was NOT
 a 401. If it ever received a 401, it tries to refresh the user tokens internally. It does this by either pausing or stopping all
 other requests in flight or in queue, and then either resuming them all after a successful refresh of the tokens, or cancelling
 them all otherwise.

 - Note: Your servers MUST validate the accesstoken that is issued with your requets with the
 [SPiD introspection](https://techdocs.spid.no/oauth/introspect/) endpoint.

 ### Errors

 1. `ClientError.userRefreshFailed`
 1. `ClientError.invalidUser`

 If there's a refresh failure, then the `User` object that is associated with this `URLSession` object is logged out, as there is no
 way to recover short of logging the user back in again.

 */
extension URLSession {
    /**
     Creates a URLSession object that is tied to a User object which means it will set authentication headers based on the
     user and also take care of any oauth intricacies that need to be handled. If you use thie URLSession that if there's
     ever a 401 status code returned by a server you hit, the User object will be refreshed autocamitally and any requests
     that were started with this URLSession will be resent after the user has be refreshed.

     - parameter: user: `User` object that you want this URLSession to be associated with
     - parameter: configuration: see docs for URLSession
     - parameter: delegate: see docs for URLSession
     - parameter: delegateQueue: see docs for URLSession
     */
    public convenience init(user: User, configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?) {
        var adjustedheaders = configuration.httpAdditionalHeaders ?? [AnyHashable: Any]()
        adjustedheaders.updateValue(String(describing: ObjectIdentifier(user).hashValue), forKey: AutoRefreshURLProtocol.key)
        adjustedheaders.updateValue(UserAgent().value, forKey: Networking.Header.xSchibstedAccountUserAgent.rawValue)
        let configurationCopy = configuration
        configurationCopy.httpAdditionalHeaders = adjustedheaders
        configurationCopy.protocolClasses = [AutoRefreshURLProtocol.self]
        self.init(configuration: configurationCopy, delegate: delegate, delegateQueue: delegateQueue)
        log(level: .verbose, from: self, "user: \(user)")
    }

    /**
     Creates a URLSession object that is tied to a User object which means it will set authentication headers based on the
     user and also take care of any oauth intricacies that need to be handled. If you use thie URLSession that if there's
     ever a 401 status code returned by a server you hit, the User object will be refreshed autocamitally and any requests
     that were started with this URLSession will be resent after the user has be refreshed.

     - parameter: user: `User` object that you want this URLSession to be associated with
     - parameter: configuration: see docs for URLSession
     */
    public convenience init(user: User, configuration: URLSessionConfiguration) {
        self.init(user: user, configuration: configuration, delegate: nil, delegateQueue: nil)
    }
}

extension URLResponse {
    func isAuthorizationFailure() -> Bool {
        if let httpResponse = self as? HTTPURLResponse, httpResponse.statusCode == 401 {
            return true
        }
        return false
    }
}
