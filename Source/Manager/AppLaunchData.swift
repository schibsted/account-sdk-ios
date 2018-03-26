//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Used to store extracted application launch data for deep linking scenarios.

 You can construct an `AppLaunchData` object in your `UIApplicationDelegate.application(:openURL:options:)`
 by either forwarding the url to the initializer or first creating a `ClientConfiguration.RedirectPayload`
 and forwarding that to the initializer.
 */
public enum AppLaunchData: Equatable {
    /// When a deep link contains an auth code after a signup attempt
    case codeAfterSignup(String, shouldPersistUser: Bool)
    /// When a deep link contains an auth code after trying to login with an unverified identifier
    case codeAfterUnvalidatedLogin(String)
    /// When a deep link returns after a forgot password session
    case afterForgotPassword

    ///
    public static func == (lhs: AppLaunchData, rhs: AppLaunchData) -> Bool {
        switch (lhs, rhs) {
        case let (.codeAfterSignup(a), .codeAfterSignup(b)):
            return a == b
        case let (.codeAfterUnvalidatedLogin(a), .codeAfterUnvalidatedLogin(b)):
            return a == b
        case (.afterForgotPassword, .afterForgotPassword):
            return true
        default:
            return false
        }
    }
}

extension AppLaunchData {
    enum QueryKey: String {
        case code
        case persistUser = "persist-user"
    }
    /**
     Initializes this object if url is a valid deep link.

     - parameter url: The url you get through `UIApplicationDelegate.application(_:url:options:)`.
     */
    public init?(launchOptions: [AnyHashable: Any]?, clientConfiguration: ClientConfiguration) {
        guard let maybeURL = launchOptions?[UIApplicationLaunchOptionsKey.url], let url = maybeURL as? URL else {
            return nil
        }
        self.init(deepLink: url, clientConfiguration: clientConfiguration)
    }

    /**
     Initializes this object if url is a valid deep link.

     - parameter url: The url you get through `UIApplicationDelegate.application(_:url:options:)`.
     */
    public init?(deepLink url: URL, clientConfiguration: ClientConfiguration) {
        guard let payload = clientConfiguration.parseRedirectURL(url) else {
            return nil
        }
        self.init(payload: payload)
    }

    /**
     Takes a redirect payload and creates the approprriate app launch information
     */
    public init?(payload: ClientConfiguration.RedirectPayload) {
        // Note: make sure to validate an variable input when possible

        guard let path = payload.path else {
            if let code = payload.queryComponents[QueryKey.code.rawValue]?.first {
                // Only ascii alpha numerics allowed in authoriation code
                guard !code.isEmpty && code.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil else {
                    return nil
                }
                self = .codeAfterUnvalidatedLogin(code)
                return
            }
            return nil
        }

        if let value = Settings.value(forKey: ClientConfiguration.RedirectInfo.Signup.settingsKey) as? String, value == path {
            guard let code = payload.queryComponents[QueryKey.code.rawValue]?.first else {
                return nil
            }
            let shouldPersistUser = payload.queryComponents[QueryKey.persistUser.rawValue]?.first == "true"
            self = .codeAfterSignup(code, shouldPersistUser: shouldPersistUser)
            return
        }

        if let value = Settings.value(forKey: ClientConfiguration.RedirectInfo.ForgotPassword.settingsKey) as? String, value == path {
            self = .afterForgotPassword
            return
        }

        return nil
    }
}
