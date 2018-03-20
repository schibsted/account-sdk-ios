//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class UserProductTests: QuickSpec {

    override func spec() {
        describe("Product data") {
            it("Should have all the fields") {
                let user = TestingUser(state: .loggedIn)
                let productID = "123"
                var stubSignup = NetworkStub(path: .path(Router.product(userID: user.id!, productID: productID).path))
                stubSignup.returnFile(file: "user-product-valid", type: "json", in: Bundle(for: TestingUser.self))
                stubSignup.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stubSignup)

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
