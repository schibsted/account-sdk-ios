//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class ClientConfigurationTests: QuickSpec {

    override func spec() {

        it("should use redirectRoot as host if default scheme") {
            let configuration = ClientConfiguration(environment: .development, clientID: "clientID", clientSecret: "clientSecret", appURLScheme: nil)
            expect(configuration.appURLScheme) == "spid-clientID"
            expect(configuration.appURLScheme) == configuration.defaultAppURLScheme
            expect(configuration.redirectBaseURL(withPathComponent: nil).absoluteString) == configuration.appURLScheme + "://" + configuration.redirectURLRoot
        }

        it("should use redirectRoot as path if not default scheme") {
            let scheme = "x.clientID"
            let configuration = ClientConfiguration(environment: .development, clientID: "clientID", clientSecret: "clientSecret", appURLScheme: scheme)
            expect(configuration.appURLScheme) == scheme
            expect(configuration.redirectBaseURL(withPathComponent: nil).absoluteString) == configuration.appURLScheme + ":/" + configuration.redirectURLRoot
        }
    }
}
