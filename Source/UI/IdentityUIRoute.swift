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
        case enterPassword(for: EmailAddress, scopes: [String])

        /// Route to the next step after email validation occurred after signup.
        case validateAuthCode(code: String, shouldPersistUser: Bool)

        var loginMethod: LoginMethod {
            switch self {
            case .login, .enterPassword, .validateAuthCode:
                return .password
            }
        }
    }
}

extension IdentityUI.Route {

    enum TypeID: String {
        case enterPassword, login, validateAuthCode
    }

    var typeID: TypeID {
        switch self {
        case .enterPassword:
            return .enterPassword
        case .login:
            return .login
        case .validateAuthCode:
            return .validateAuthCode
        }
    }

    var persistedData: Data? {
        var json: JSONObject = [:]
        switch self {
        case let .enterPassword(for: email, scopes: scopes):
            json = [
                "email": email.normalizedString,
                "scopes": scopes.joined(separator: " "),
            ]
        case .login, .validateAuthCode:
            break
        }
        json["type"] = self.typeID.rawValue
        return json.data()
    }

    static func parse(data: Data, expecting expectedTypeID: IdentityUI.Route.TypeID) -> IdentityUI.Route? {
        guard let json = try? data.jsonObject(), let typeString = try? json.string(for: "type") else {
            return nil
        }
        guard typeString == expectedTypeID.rawValue, let typeID = TypeID(rawValue: typeString) else {
            return nil
        }
        switch typeID {
        case .enterPassword:
            guard
                let string = try? json.string(for: "email"),
                let email = EmailAddress(string),
                let scopes = try? json.string(for: "scopes").split(separator: " ").map({ String($0) })
                else {
                return nil
            }
            return .enterPassword(for: email, scopes: scopes)
        default:
            return nil
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
            guard let persistedData = IdentityUI.Route.loadLastPersistedMetadata() else {
                self = .login
                return
            }
            if let parsedRoute = IdentityUI.Route.parse(data: persistedData, expecting: .enterPassword) {
                self = parsedRoute
                return
            }
        case let .codeAfterSignup(code, shouldPersistUser):
            self = .validateAuthCode(code: code, shouldPersistUser: shouldPersistUser)
            return
        case let .codeAfterUnvalidatedLogin(code):
            // We have no way to retrieve the `shouldPersistUser` flag from the redirect URL in this case, so we just fall back to `false`.
            self = .validateAuthCode(code: code, shouldPersistUser: false)
            return
        }
        return nil
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
        if let data = route.persistedData {
            Settings.setValue(data, forKey: IdentityUI.Route.lastPersistentMetadataStoredKey)
        }
    }

    fileprivate static func loadLastPersistedMetadata() -> Data? {
        return Settings.value(forKey: IdentityUI.Route.lastPersistentMetadataStoredKey) as? Data
    }
}
