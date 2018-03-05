//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class UserAgentTests: QuickSpec {

    override func spec() {
        describe("User agent") {
            it("Should output the expected value") {
                struct DeviceInfo: SchibstedAccount.DeviceInfo {
                    let deviceModel = "iPhone"
                    let systemName = "iOS"
                    let systemVersion = "11.2"
                }

                let userAgent = UserAgent(sdkVersion: "1.0.2", deviceInfo: DeviceInfo())
                expect(userAgent.value) == "SchibstedAccountSDK/1.0.2 (iPhone; iOS 11.2)"
            }
        }
    }
}
