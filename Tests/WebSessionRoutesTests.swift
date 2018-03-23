//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Nimble
import Quick
@testable import SchibstedAccount

extension URL {
    var redirectURLComponent: String? {
        return URLComponents(url: self, resolvingAgainstBaseURL: true)!
            .queryItems?
            .filter({ $0.name == "redirect_uri" })
            .first?
            .value?
            .removingPercentEncoding
    }
}

class WebSessionRoutesTests: QuickSpec {

    override func spec() {

        it("Should create all routes") {
            let routes = WebSessionRoutes(clientConfiguration: .testing)
            _ = routes.logoutURL
            _ = routes.forgotPasswordURL
            _ = routes.accountSummaryURL
        }

        it("should attach query items") {
            let routes = WebSessionRoutes(clientConfiguration: .testing)
            let url = routes.makeURLFromPath("/path", redirectPath: "redirectPath", queryItems: [URLQueryItem(name: "a", value: "b")])

            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)!.queryItems!
            let clientID = queryItems.filter({ $0.name == "client_id" }).first!.value!
            let redirectURI = queryItems.filter({ $0.name == "redirect_uri" }).first!.value!
            let customKey = queryItems.filter({ $0.name == "a" }).first!.value!

            expect(clientID) == ClientConfiguration.testing.clientID
            expect(customKey) == "b"
            expect(URL(string: redirectURI)?.query?.contains("redirectPath")) == true
        }

        it("should work with default scheme") {
            let configuration = ClientConfiguration(
                serverURL: URL(string: "http://localhost:5050")!,
                clientID: "123",
                clientSecret: "123",
                appURLScheme: nil
            )
            let routes = WebSessionRoutes(clientConfiguration: configuration)
            let url = routes.makeURLFromPath("/path", redirectPath: "redirect", queryItems: [])

            let redirectURL = URL(string: url.redirectURLComponent!)!

            expect(redirectURL.scheme) == configuration.appURLScheme
            expect(redirectURL.host) == configuration.redirectURLRoot
            expect(redirectURL.pathComponents.count) == 0
            expect(redirectURL.query) == "path=redirect"
        }

        it("should work with custom scheme") {
            let configuration = ClientConfiguration(
                serverURL: URL(string: "http://localhost:5050")!,
                clientID: "123",
                clientSecret: "123",
                appURLScheme: "blah.123"
            )

            let routes = WebSessionRoutes(clientConfiguration: configuration)
            let url = routes.makeURLFromPath("/path", redirectPath: "redirect", queryItems: [])

            let redirectURL = URL(string: url.redirectURLComponent!)!

            expect(redirectURL.scheme) == configuration.appURLScheme
            expect(redirectURL.host).to(beNil())
            expect(redirectURL.pathComponents.count) == 2
            expect(redirectURL.pathComponents[1]) == "login"
            expect(redirectURL.query) == "path=redirect"
        }
    }
}
