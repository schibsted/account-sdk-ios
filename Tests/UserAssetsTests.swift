//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class UserAssetsTests: QuickSpec {

    override func spec() {
        describe("User's Assets") {
            it("Should have all the fields") {
                let user = TestingUser(state: .loggedIn)
                var stubSignup = NetworkStub(path: .path(Router.assets(userID: user.id!).path))
                stubSignup.returnData(json: .fromFile("user-assets-valid"))
                stubSignup.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stubSignup)

                user.assets.fetch { result in
                    guard case let .success(userAssets) = result else {
                        return fail()
                    }
                    
                    expect(userAssets.assets).to(haveCount(1))
                    
                    guard let asset = userAssets.assets?.first else { return fail() }
                    
                    expect(asset.merchantID).to(equal(12345))
                    expect(asset.assetID).to(equal("Fotballpakka"))
                    expect(asset.userID).to(equal(9876543))
                    expect(asset.uuid).to(equal("12345678-9012-3456-7890-123456789012"))
                    expect(asset.status).to(equal(.active))
                    expect(asset.updated).to(equal(DateFormatter.local.date(from: "2018-08-01 09:02:08")))
                    expect(asset.created).to(equal(DateFormatter.local.date(from: "2018-07-30 10:27:18")))
                }
            }
        }
    }
}

private extension DateFormatter {
    static let local: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
