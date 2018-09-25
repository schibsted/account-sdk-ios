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
    /// When deep link returns after an account summary session
    case codeAfterAccountSummary(String)
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
        guard let maybeURL = launchOptions?[UIApplication.LaunchOptionsKey.url], let url = maybeURL as? URL else {
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

        // See if there's an auth code here first, then we have one of the code related deep links
        if let code = payload.queryComponents[QueryKey.code.rawValue]?.first {
            guard !code.isEmpty && code.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil else {
                return nil
            }

            // No path, means a deeplink from a login where the email address was not verified previously
            guard let path = payload.path else {
                self = .codeAfterUnvalidatedLogin(code)
                return
            }

            // Check if coming back from signup
            if let value = Settings.value(forKey: ClientConfiguration.RedirectInfo.Signup.settingsKey) as? String, value == path {
                let shouldPersistUser = payload.queryComponents[QueryKey.persistUser.rawValue]?.first == "true"
                self = .codeAfterSignup(code, shouldPersistUser: shouldPersistUser)
                return
            }

            // Check if coming back after account summary session
            if let value = Settings.value(forKey: ClientConfiguration.RedirectInfo.AccountSummary.settingsKey) as? String, value == path {
                self = .codeAfterAccountSummary(code)
                return
            }

            // Unknwon path
            return nil
        }

        // Check for paths with no code

        guard let path = payload.path else {
            return nil
        }

        if let value = Settings.value(forKey: ClientConfiguration.RedirectInfo.ForgotPassword.settingsKey) as? String, value == path {
            self = .afterForgotPassword
            return
        }

        return nil
    }
}
