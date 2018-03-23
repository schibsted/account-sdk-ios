//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class AppLaunchDataTests: QuickSpec {

    override func spec() {

        it("Should get code after signup if setting set") {
            let path = "signup"
            Settings.setValue(path, forKey: ClientConfiguration.RedirectInfo.Signup.settingsKey)
            let url = ClientConfiguration.testing.redirectBaseURL(withPathComponent: path)
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems?.append(URLQueryItem(name: "code", value: "9158"))
            let appData = AppLaunchData(deepLink: components.url!, clientConfiguration: .testing)
            expect(appData).to(equal(AppLaunchData.codeAfterSignup("9158", shouldPersistUser: false)))
        }

        it("Should get code after login if no path") {
            let url = ClientConfiguration.testing.redirectBaseURL(withPathComponent: nil)
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems = [URLQueryItem(name: "code", value: "9158")]
            let appData = AppLaunchData(deepLink: components.url!, clientConfiguration: .testing)
            expect(appData).to(equal(AppLaunchData.codeAfterUnvalidatedLogin("9158")))
        }

        it("Should get code after login if no path even if signup setting present") {
            let path = "signup"
            Settings.setValue(path, forKey: ClientConfiguration.RedirectInfo.Signup.settingsKey)
            let url = ClientConfiguration.testing.redirectBaseURL(withPathComponent: nil)
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems = [URLQueryItem(name: "code", value: "9158")]
            let appData = AppLaunchData(deepLink: components.url!, clientConfiguration: .testing)
            expect(appData).to(equal(AppLaunchData.codeAfterUnvalidatedLogin("9158")))
        }

        it("should try to ignore non alphanumeric code query item values") {
            let path = "signup"
            Settings.setValue(path, forKey: ClientConfiguration.RedirectInfo.Signup.settingsKey)
            let url = ClientConfiguration.testing.redirectBaseURL(withPathComponent: path)
            do {
                // Check diacritic fails
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                components.queryItems = [URLQueryItem(name: "code", value: "11çjj")]
                expect(AppLaunchData(deepLink: components.url!, clientConfiguration: .testing)).to(beNil())
            }
            do {
                // Check non alpha numeric fails
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                components.queryItems = [URLQueryItem(name: "code", value: "aa!11")]
                expect(AppLaunchData(deepLink: components.url!, clientConfiguration: .testing)).to(beNil())
            }
        }
    }
}
