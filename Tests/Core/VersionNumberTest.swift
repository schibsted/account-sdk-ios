//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class VersionNumberTest: QuickSpec {
    override func spec() {
        describe("SDK version number") {
            it("Should match the one in the bundle") {
                let bundleVersionNumber = Bundle(for: IdentityUI.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                expect(SchibstedAccount.sdkVersion) == bundleVersionNumber
            }
        }
    }
}
