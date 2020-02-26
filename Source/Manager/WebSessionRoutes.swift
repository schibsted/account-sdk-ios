//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import CommonCrypto
import Foundation

/**
 Schibsted account web page URLs useful for web views in hybrid apps.
 */
public class WebSessionRoutes {
    private let clientConfiguration: ClientConfiguration

    internal struct WebFlowData: Codable {
        let state: String
        let codeVerifier: String
        let shouldPersistUser: Bool
    }

    func makeURLFromPath(_ path: String, redirectPath: String?, queryItems: [URLQueryItem], redirectQueryItems: [URLQueryItem]?) -> URL {
        let redirectURL = clientConfiguration.redirectBaseURL(withPathComponent: redirectPath, additionalQueryItems: redirectQueryItems)
        guard var urlComponents = URLComponents(url: clientConfiguration.serverURL, resolvingAgainstBaseURL: true) else {
            preconditionFailure("Failed to create URLComponents from \(clientConfiguration.serverURL)")
        }
        urlComponents.path = path
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: clientConfiguration.clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURL.absoluteString),
        ]
        urlComponents.queryItems?.append(contentsOf: queryItems)
        guard let url = urlComponents.url else {
            preconditionFailure("Failed to create URL from \(urlComponents)")
        }
        log(from: self, "returning route \(url)")
        return url
    }

    init(clientConfiguration: ClientConfiguration) {
        self.clientConfiguration = clientConfiguration
    }

    /**
     Schibsted account "logout" action URL

     Use this URL for a web view that has a web session (Schibsted account cookie).
     Navigation such a web view will logout the web user inside.
     */
    public var logoutURL: URL {
        return self.logoutURL(withRedirectPath: nil)
    }
    /// Allows to customize redirectPath
    public func logoutURL(withRedirectPath path: String? = nil) -> URL {
        return makeURLFromPath("/logout", redirectPath: path, queryItems: [], redirectQueryItems: nil)
    }

    /**
     Schibsted account "forgot password" web page URL

     Navigate a web view with this URL to show a password reminder form.
     */
    public var forgotPasswordURL: URL {
        return self.forgotPasswordURL(withRedirectPath: ClientConfiguration.RedirectInfo.ForgotPassword.path)
    }

    /**
     Same as `forgotPasswordURL` but customizable

     - parameter withRedirectPath: the redirect path that will be injected in the URL
     - parameter redirectQueryItems: any query items you want the redirect url to contain
     */
    public func forgotPasswordURL(withRedirectPath path: String? = nil, redirectQueryItems: [URLQueryItem]? = nil) -> URL {
        Settings.setValue(path, forKey: ClientConfiguration.RedirectInfo.ForgotPassword.settingsKey)
        return makeURLFromPath("/flow/password", redirectPath: path, queryItems: [], redirectQueryItems: redirectQueryItems)
    }

    /**
     Schibsted account "account summary" web page URL

     Navigate a web view with this URL to go to user accounts page
     */
    public var accountSummaryURL: URL {
        return self.accountSummaryURL(withRedirectPath: ClientConfiguration.RedirectInfo.AccountSummary.path)
    }

    /**
     Same as `accountSummaryURL` but customizable

     - parameter withRedirectPath: the redirect path that will be injected in the URL
     - parameter redirectQueryItems: any query items you want the redirect url to contain
     */
    public func accountSummaryURL(withRedirectPath path: String? = nil, redirectQueryItems: [URLQueryItem]? = nil) -> URL {
        Settings.setValue(path, forKey: ClientConfiguration.RedirectInfo.AccountSummary.settingsKey)
        return makeURLFromPath(
            "/account/summary",
            redirectPath: path,
            queryItems: [URLQueryItem(name: "response_type", value: "code")],
            redirectQueryItems: redirectQueryItems
        )
    }

    /**
     Schibsted account web login URL.

     Navigate a web view with this URL to show the web login. Can also be used to pick up an already logged in user session in the browser
     and get a logged in user in the native app.

     - parameter shouldPersistUser: whether logging in via web flow should result in persistent user
     - parameter scopes: optional scopes to include in the authentication request
     */
    public func loginUrl(shouldPersistUser: Bool, scopes: [String]? = nil) -> URL {
        let state = randomString(length: 10)
        let codeVerifier = randomString(length: 60)
        let webFlowData = WebFlowData(state: state, codeVerifier: codeVerifier, shouldPersistUser: shouldPersistUser)

        if let encoded = try? JSONEncoder().encode(webFlowData) {
            Settings.setValue(encoded, forKey: ClientConfiguration.RedirectInfo.WebFlowLogin.settingsKey)
        }

        let scopeString = scopes.map { $0.joined(separator: " ") } ?? "openid"
        let authRequestParams = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopeString),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "nonce", value: randomString(length: 10)),
            URLQueryItem(name: "new-flow", value: "true"),
            URLQueryItem(name: "code_challenge", value: codeChallenge(from: codeVerifier)),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]

        return makeURLFromPath(
            "/oauth/authorize",
            redirectPath: nil,
            queryItems: authRequestParams,
            redirectQueryItems: nil
        )
    }

    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    private func codeChallenge(from codeVerifier: String) -> String {
        func base64url(data: Data) -> String {
            let base64url = data.base64EncodedString()
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "=", with: "")
            return base64url
        }

        func sha256(data: Data) -> Data {
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            data.withUnsafeBytes {
                _ = CC_SHA256($0, CC_LONG(data.count), &hash)
            }
            return Data(bytes: hash)
        }

        return base64url(data: sha256(data: Data(codeVerifier.utf8)))
    }
}
