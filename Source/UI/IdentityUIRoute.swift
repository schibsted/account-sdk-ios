//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension IdentityUI {
    /// Route to a specific screen in the identity UI flow. A route is typically constructed in order to handle a universal (i.e. deep) link URL so that the
    /// identity process can then be presented by going directly to the screen corresponding to the URL.
    public enum Route {
        /// Route to the initial login screen.
        case login

        /// Route to the screen where the user can enter her password. The user's email should have previously been saved by calling
        /// `IdentityUI.Route.storePersistentMetadata(for:)`, so it's made available again as an associated value when constructing the route from a URL.
        case enterPassword(for: EmailAddress, scopes: [String])

        /// Route to validate an authcode
        case validateAuthCode(code: String, shouldPersistUser: Bool?)

        var loginMethod: LoginMethod {
            switch self {
            case .login, .enterPassword, .validateAuthCode:
                return .password
            }
        }
    }
}

extension IdentityUI.Route {
    /// Initializes a new route from the given universal (i.e. deep) link URL and configuration. The initializer returns `nil` in case the given URL isn't
    /// recognized as part of an identity process (so that you can possibly handle it in a different way in case you have universal links other than the ones
    /// coming from the identity process).
    ///
    /// - Parameters:
    ///   - url: The given URL.
    ///   - configuration: The given configuration.
    public init?(url: URL, configuration: ClientConfiguration) {
        guard let payload = configuration.parseRedirectURL(url) else {
            return nil
        }
        self.init(payload: payload, configuration: configuration)
    }

    /**
     Initializes a new route from the given `ClientConfiguration.RedirectPayload` object. The initializer returns `nil` in case nothing can be done with the
     given payload

     - parameter payload: The given redirect payload.
     */
    public init?(payload: ClientConfiguration.RedirectPayload, configuration: ClientConfiguration) {
        guard let launchData = AppLaunchData(payload: payload) else {
            self = .login
            return
        }

        switch launchData {
        case .afterForgotPassword:
            let scopes = payload.queryComponents["scopes"]?.first?.split(separator: " ").map { String($0) } ?? []
            guard
                let localID = payload.queryComponents["local_id"]?.first,
                let identifier = Identifier(localID: localID),
                case let .email(email) = identifier
            else {
                self = .login
                return
            }
            self = .enterPassword(for: email, scopes: scopes)
        case let .codeAfterSignup(code, shouldPersistUser):
            self = .validateAuthCode(code: code, shouldPersistUser: shouldPersistUser)
        case let .codeAfterUnvalidatedLogin(code):
            // We have no way to retrieve the `shouldPersistUser` flag from the redirect URL in this case, so we just fall back to `false`.
            self = .validateAuthCode(code: code, shouldPersistUser: false)
        case let .codeAfterAccountSummary(code):
            self = .validateAuthCode(code: code, shouldPersistUser: nil)
        case let .codeAfterWebFlowLogin(code):
            self = .validateAuthCode(code: code, shouldPersistUser: configuration.webFlowLoginShouldPersistUser)
        }
    }
}
