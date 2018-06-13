//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Configuration for your client. Allows client to set their ID and decide
 which backend environment to point the SDK at.

 This is the first structure you must create in your SDK. Typically, an application will
 have one for testing/debugging purposes and one that is used in a production environment.
 A tip for organizing them would be to have it globally available in your applications:

 ```
 extension ClientConfiguration {
   static let debug = ClientConfiguration(
     ...
   )

   static let production = ClientConfiguration(
     ...
   )
 }
 ```

 API calls will NOT work accross different ClientConfiguration objects. If you have state
 that is left over after using one ClientConfiguration, and then you try and use that state
 with a different ClientConfiguration, you will not get the results you want.

 This object is used to set your `ClientConfiguration.Environment`, your
 `ClientConfiguration.appURLScheme` and your locale.

 ### App URL Scheme

 If you want deep linking to work, then you must specify your app's URL scheme as well.
 For SPiD mobile clients, the scheme is fixed and is available from the SPiD self-service
 portal.

 You should specify this string value when creating your ClientConfiguration and you should
 also register the url scheme as per Apple guidelines.

 - SeeAlso: [SPiD selfservice](http://techdocs.spid.no/selfservice/access/)
 - SeeAlso: [Apple docs: Inter App Communication](
        https://developer.apple.com/library/content/documentation/iPhone/Conceptual/
iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html#
//apple_ref/doc/uid/TP40007072-CH6-SW1)

 */
public struct ClientConfiguration {
    /**
     Determines which backend requests will be sent to. Most of the values here are
     explained on the SPiD self service site where you also must set up your client.

     Basically this is what determines if this is a production configuration, or
     pre production, etc. Please read the [SPiD selfservice](http://techdocs.spid.no/selfservice/access/)

     - SeeAlso: [SPiD selfservice](http://techdocs.spid.no/selfservice/access/)
     */
    public enum Environment: String {
        /// login.schibsted.com
        case production
        /// identity-pre.schibsted.com
        case preproduction
        /// identity-dev.schibsted.com
        case development
        /// payment.schibsted.no
        case norway

        fileprivate static func loadConfigurationData() -> [String: [String: String]] {
            guard let configFile = Bundle(for: IdentityManager.self).path(forResource: "Configuration", ofType: "plist") else {
                preconditionFailure("Configuration.plist file not found in bundle")
            }
            guard let config = NSDictionary(contentsOfFile: configFile) as? [String: [String: String]] else {
                preconditionFailure("Could not load Configuration.plist as Dictionary")
            }
            return config
        }

        fileprivate func loadConfiguration() -> (serverURL: URL, trackingProvider: String?) {
            let config = Environment.loadConfigurationData()
            let env = String(describing: self)
            guard let serverURL = URL(string: config[env]?["url"] ?? "about:blank") else {
                preconditionFailure("Could not load url from configuration environment: \(env)")
            }
            let trackingProviderComponent = config[env]?["provider"]
            return (serverURL, trackingProviderComponent)
        }

        fileprivate static func dataForServerURL(_ serverURL: URL) -> (environment: Environment, trackingProvider: String?)? {
            let config = Environment.loadConfigurationData()
            for pair in config {
                guard let string = pair.value["url"], let url = URL(string: string) else { continue }
                if url == serverURL, let env = Environment(rawValue: pair.key) {
                    return (env, pair.value["provider"])
                }
            }
            return nil
        }
    }

    /**
     All SDK requests will be served to this URL.

     Is is either determined by an `Environment` that you specify or can also be a custom URL, which may be
     handy for local testing.
     */
    public let serverURL: URL

    /// The client id that this object was initialized with
    public let clientID: String

    let providerComponent: String?
    let clientSecret: String

    /// The locale that is being used
    public let locale: Locale

    /**
     Which environment (if any) is this configuration using
     */
    public let environment: Environment?

    /**
     Alternative initializer if you do not want to specify a pre-existing `Environment`. Usually used for testing.

     - parameter serverURL: the backend server URL to talk to.
     - parameter providerComponent: the backend server provider URN.
     - parameter clientID: unique client identifier for this client.
     - parameter clientSecret: the secret associated with the client ID
     - parameter appURLScheme: set your `appURLSceheme` here. Defaults to "spid-\(clientID)" if nil
     - parameter locale: Locale you want to use for requests - defaults to system
     */
    public init(serverURL: URL, clientID: String, clientSecret: String, appURLScheme: String?, locale: Locale? = nil) {
        let data = Environment.dataForServerURL(serverURL)
        self.init(
            environment: data?.environment,
            serverURL: serverURL,
            providerComponent: data?.trackingProvider,
            clientID: clientID,
            clientSecret: clientSecret,
            appURLScheme: appURLScheme,
            locale: locale
        )
    }

    private init(
        environment: Environment?,
        serverURL: URL,
        providerComponent: String?,
        clientID: String,
        clientSecret: String,
        appURLScheme: String?,
        locale: Locale? = nil
    ) {
        self.serverURL = serverURL
        self.providerComponent = providerComponent
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.locale = locale ?? Locale.current
        let defaultAppURLScheme = "spid-\(clientID)"
        self.appURLScheme = appURLScheme ?? defaultAppURLScheme
        self.defaultAppURLScheme = defaultAppURLScheme
        self.environment = environment
        precondition(self.appURLScheme.contains(self.clientID), "Valid appURLSchemes must contain the clientID in it")
    }

    let defaultAppURLScheme: String

    /**
     Initialize a new configuration for a specific `Environment`

     - parameter environment: the backend environment to talk to. Can be one of the pre-defined environments.
     - parameter clientID: unique client identifier for this client.
     - parameter clientSecret: the secret associated with the client ID
     - parameter appURLScheme: set your `appURLSceheme`. Defaults to "spid-\(clientID)" if nil
     - parameter locale: Locale you want IdentityManager to use for requests
     */
    public init(environment: Environment, clientID: String, clientSecret: String, appURLScheme: String?, locale: Locale? = nil) {
        let envConfig = environment.loadConfiguration()
        self.init(
            environment: environment,
            serverURL: envConfig.serverURL,
            providerComponent: envConfig.trackingProvider,
            clientID: clientID,
            clientSecret: clientSecret,
            appURLScheme: appURLScheme,
            locale: locale
        )
    }

    /**
     This is used for generating the redirect URI needed for going back to the app. You can find this in the SPiD selfservice
     under the "Redirect" tab for your client. It **must** be equal to the value under "Custom URI Scheme"

     You will also have to register the scheme in the your apps Info.plist "URL Types" under "URL Schemes".

     - SeeAlso: [Apple docs: Inter App Communication](
     https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html)
     */
    public let appURLScheme: String

    /**
     This will be used when creating any redirect URIs. How it's used depends on the appURLScheme. If it is the
     default one (spid-<client-id>) it will be added as a host. If it is anything else, it will be added as a path
     with an empty url host (i.e. no authority part)

     This is also determined by selfservice and is currently unchangeable.

     - SeeAlso appURLScheme
     */
    let redirectURLRoot = "login"

    /**
     Base URL for redirects that will be created by the SDK for various API calls.

     The way this is constructed depends on your `appURLScheme`. The SDK currently supports two formats that SPiD uses:

     1. format0 - this is in the format of "spid-<client-id>" - SDK treats this as default.
     1. format1 - this is in the format of "<reverse-dns-of-your-service-domain>.<client-id>"

     SPiD has a number of default routes set up for mobile clients (referred to as roots in the SDK - see `redirectURLRoot`). The way these are added
     to a redirect depends on the format of your app scheme.

     With format0 SPiD adds the root s a URL host component. I.e. scheme://root. This is usually "login" and the SDK defaults to that, but it
     can be others (see your self service and they will be listed there). For format1, the root is a URL path component. I.e. scheme://host/path-component.
     And the host (or more accurately "authority") URL component is omitted, which means the format is: scheme:/root

     - parameter withPathComponent: if specified, a "path" url query item will be added to the URL with the value of this argument
     - parameter additionalQueryItems: if you want any additional query items added to the URL

     - SeeAlso `redirectURLRoot`
     */
    public func redirectBaseURL(withPathComponent path: String?, additionalQueryItems: [URLQueryItem]? = nil) -> URL {
        var components = URLComponents()
        components.scheme = self.appURLScheme
        if self.appURLScheme == self.defaultAppURLScheme {
            components.host = self.redirectURLRoot
        } else {
            components.path = "/" + self.redirectURLRoot
        }
        if let path = path {
            components.queryItems = (additionalQueryItems ?? []) + [URLQueryItem(name: RedirectInfo.pathKey, value: path)]
        } else {
            components.queryItems = additionalQueryItems
        }
        guard let url = components.url else {
            preconditionFailure("Failed to create URL out of app scheme")
        }
        return url
    }

    /**
     The result of parsing a redirect URL deep link
     */
    public typealias RedirectPayload = (path: String?, queryComponents: [String: [String]])

    /**
     Returns a `RedirectPayload` that contains data that can be used by `AppLaunchData` to
     extract deep link related information

     The redirectURL must have been generated via `redirectBaseURL` and contain
     the `appURLScheme` inside for it to be valid.

     - returns: A tuple of path and queryComponents if the URL was a valid redirectURL
     */
    public func parseRedirectURL(_ redirectURL: URL) -> RedirectPayload? {
        guard redirectURL.scheme?.contains(self.clientID) ?? false else {
            return nil
        }

        // old style scheme has a host, which is the "root"
        // new style scheme with no host, where path is "/<root>"
        guard redirectURL.host == self.redirectURLRoot || redirectURL.pathComponents == ["/", self.redirectURLRoot] else {
            return nil
        }

        var maybePath: String?
        let queryComponents = URLComponents(url: redirectURL, resolvingAgainstBaseURL: true)?.queryItems?.reduce([String: [String]]()) { memo, item in
            var memo = memo
            if let value = item.value {
                if item.name == RedirectInfo.pathKey {
                    maybePath = item.value
                    return memo
                }
                memo[item.name] = memo[item.name] ?? []
                memo[item.name]?.append(value)
            }
            return memo
        } ?? [:]

        return (maybePath, queryComponents)
    }

    struct RedirectInfo {
        static let pathKey = "path"
        static let persistUserKey = "persist-user"

        struct Signup {
            static let settingsKey = "RedirectInfo.Signup"
            static let path = "validate-after-signup"
        }

        struct ForgotPassword {
            static let settingsKey = "RedirectInfo.ForgotPassword"
            static let path = "enter-password"
        }

        struct AccountSummary {
            static let settingsKey = "RedirectInfo.AccountSummary"
            static let path = "account-summary"
        }
    }
}

extension ClientConfiguration: Equatable {
    public static func == (lhs: ClientConfiguration, rhs: ClientConfiguration) -> Bool {
        return lhs.serverURL == rhs.serverURL
            && lhs.providerComponent == rhs.providerComponent
            && lhs.clientID == rhs.clientID
            && lhs.clientSecret == rhs.clientSecret
            && lhs.locale == rhs.locale
            && lhs.appURLScheme == rhs.appURLScheme
            && lhs.defaultAppURLScheme == rhs.defaultAppURLScheme
            && lhs.environment == rhs.environment
            && lhs.redirectURLRoot == rhs.redirectURLRoot
    }
}
