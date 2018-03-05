//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Mockingjay
import Nimble
import Quick
@testable import SchibstedAccount

class UserProductTests: QuickSpec {

    override func spec() {
        describe("Product data") {
            it("Should have all the fields") {
                let user = TestingUser(state: .loggedIn)
                let productID = "123"
                self.stub(uri("/api/2/user/\(user.id!)/product/\(productID)"), try! Builders.load(file: "user-product-valid", status: 200))

                user.product.fetch(productID: productID) { result in
                    guard case let .success(product) = result else {
                        return fail()
                    }
                    expect(product.productID).to(equal(productID))
                    expect(product.result).to(equal(true))
                }
            }
        }
    }
}
