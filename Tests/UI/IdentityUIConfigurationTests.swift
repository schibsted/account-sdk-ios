//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class IdentityUIConfigurationTests: QuickSpec {

    override func spec() {

        it("Should get bundle name as appName if not set") {
            let configuration = IdentityUIConfiguration.testing
            expect(configuration.appName) == "Example"
        }

        it("Should get set name as appName") {
            var configuration = IdentityUIConfiguration.testing
            configuration.appName = "howdy"
            expect(configuration.appName) == "howdy"
        }
    }
}
