//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class RequiredFieldValidationTests: QuickSpec {

    override func spec() {

        it("Should handle birthday formatting") {
            let birthday = SupportedRequiredField.birthday
            expect(birthday.format(oldValue: "888", with: "8888")) == "8888-"
            expect(birthday.format(oldValue: "8888-8", with: "8888-88")) == "8888-88-"
            expect(birthday.format(oldValue: "8888-88-8", with: "8888-88-88")) == "8888-88-88"
            expect(birthday.format(oldValue: "8888-88-", with: "8888-88")) == "8888-8"
        }
    }
}
