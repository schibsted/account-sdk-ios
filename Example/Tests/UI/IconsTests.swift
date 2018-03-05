//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class IconsTests: QuickSpec {

    override func spec() {

        it("Should have colors for all kinds") {
            for kind in Utils.iterateEnum(StyleIconKind.self) {
                expect(Style.icons[kind]).toNot(beNil())
            }
        }
    }
}
