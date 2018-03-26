//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
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
        case enterPassword(for: EmailAddress)

        /// Route to the next step after email validation occurred after signup.
        case validateAuthCode(code: String, shouldPersistUser: Bool)

        /// Route to present updated terms and condition to an already logged-in user.
        case presentUpdatedTerms

        var loginMethod: LoginMethod {
            switch self {
            case .login, .enterPassword, .validateAuthCode:
                return .password
            case .presentUpdatedTerms:
                // Not really relevant in this case.
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
        self.init(payload: payload)
    }

    /**
     Initializes a new route from the given `ClientConfiguration.RedirectPayload` object. The initializer returns `nil` in case nothing can be done with the
     given payload

     - parameter payload: The given redirect payload.
     */
    public init?(payload: ClientConfiguration.RedirectPayload) {
        guard let launchData = AppLaunchData(payload: payload) else {
            self = .login
            return
        }

        switch launchData {
        case .afterForgotPassword:
            guard let string: String = IdentityUI.Route.loadLastPersistedMetadata(), let email = EmailAddress(string) else {
                self = .login
                return
            }
            self = .enterPassword(for: email)
        case let .codeAfterSignup(code, shouldPersistUser):
            self = .validateAuthCode(code: code, shouldPersistUser: shouldPersistUser)
        case let .codeAfterUnvalidatedLogin(code):
            // We have no way to retrieve the `shouldPersistUser` flag from the redirect URL in this case, so we just fall back to `false`.
            self = .validateAuthCode(code: code, shouldPersistUser: false)
        }
    }
}

extension IdentityUI.Route {
    private static let lastPersistentMetadataStoredKey = "route.persistent-metadata"

    /// Should be called to persistently store some data associated to the route so that it can later been retrieved when the same route is constructed to
    /// handle a universal (i.e. deep) link. For instance, it is used to store the user's email when requesting a password change, so that the email can later
    /// be prefilled when opening the app due to the change confirmation deep link.
    ///
    /// - Parameter route: The route with associated metadata to be stored. At the moment, only `.enterPassword` is supported.
    ///
    /// - Note: Metadata for a single route can be persisted at a time, since persisting new metadata will replace previously persisted one.
    static func persistMetadata(for route: IdentityUI.Route) {
        switch route {
        case .login, .validateAuthCode(code: _), .presentUpdatedTerms:
            // No persistent metadata need to be stored.
            return
        case let .enterPassword(for: email):
            // Metadata replaces old one (if any).
            Settings.setValue(email.normalizedString, forKey: IdentityUI.Route.lastPersistentMetadataStoredKey)
        }
    }

    fileprivate static func loadLastPersistedMetadata<T>() -> T? {
        return Settings.value(forKey: IdentityUI.Route.lastPersistentMetadataStoredKey) as? T
    }
}
