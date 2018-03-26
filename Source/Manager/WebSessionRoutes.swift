//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 SPID web page URLs useful for web views in hybrid apps.
*/
public class WebSessionRoutes {
    private let clientConfiguration: ClientConfiguration

    func makeURLFromPath(_ path: String, redirectPath: String?, queryItems: [URLQueryItem]) -> URL {
        let redirectURL = self.clientConfiguration.redirectBaseURL(withPathComponent: redirectPath)
        guard var urlComponents = URLComponents(url: self.clientConfiguration.serverURL, resolvingAgainstBaseURL: true) else {
            preconditionFailure("Failed to create URLComponents from \(self.clientConfiguration.serverURL)")
        }
        urlComponents.path = path
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: self.clientConfiguration.clientID),
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
     SPID "logout" action URL

     Use this URL for a web view that has a web session (SPID cookie).
     Navigation such a web view will logout the web user inside.
     */
    public var logoutURL: URL {
        return self.logoutURL(withRedirectPath: nil)
    }
    /// Allows to customize redirectPath
    public func logoutURL(withRedirectPath path: String? = nil) -> URL {
        return self.makeURLFromPath("/logout", redirectPath: path, queryItems: [])
    }

    /**
     SPID "forgot password" web page URL

     Navigate a web view with this URL to show a password reminder form.
     */
    public var forgotPasswordURL: URL {
        return self.forgotPasswordURL(withRedirectPath: ClientConfiguration.RedirectInfo.ForgotPassword.path)
    }
    /// Allows to customize redirectPath
    public func forgotPasswordURL(withRedirectPath path: String? = nil) -> URL {
        Settings.setValue(path, forKey: ClientConfiguration.RedirectInfo.ForgotPassword.settingsKey)
        return self.makeURLFromPath("/flow/password", redirectPath: path, queryItems: [])
    }

    /**
     SPID "account summary" web page URL

     Navigate a web view with this URL to go to user accounts page
     */
    public var accountSummaryURL: URL {
        return self.accountSummaryURL(withRedirectPath: nil)
    }
    /// Allows to customize redirectPath
    public func accountSummaryURL(withRedirectPath path: String? = nil) -> URL {
        return self.makeURLFromPath("/account/summary", redirectPath: path, queryItems: [])
    }
}
