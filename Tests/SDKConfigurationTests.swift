//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class SDKConfigurationTests: QuickSpec {

    override func spec() {

        describe("Agreements cache") {
            it("should cache network requests for agreements tasks if set to on") {
                SDKConfiguration.shared.agreementsCache = SDKConfiguration.AgreementsCache(
                    isOn: true,
                    minDays: 1,
                    maxDays: 2
                )

                let user = TestingUser(state: .loggedIn)

                var stub = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                stub.returnData(json: .fromFile("agreements-valid-unaccepted"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                user.agreements.status { _ in }
                user.agreements.status { _ in }
                user.agreements.status { _ in }

                expect(Networking.testingProxy.callCount) == 1
            }

            it("should cache network requests for agreements tasks if set to off") {
                SDKConfiguration.shared.agreementsCache = SDKConfiguration.AgreementsCache(
                    isOn: false,
                    minDays: 1,
                    maxDays: 2
                )

                let user = TestingUser(state: .loggedIn)

                var stub = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                stub.returnData(json: .fromFile("agreements-valid-unaccepted"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                user.agreements.status { _ in }
                user.agreements.status { _ in }
                user.agreements.status { _ in }

                expect(Networking.testingProxy.callCount) == 3
            }

            it("should update status on set") {
                SDKConfiguration.shared.agreementsCache = SDKConfiguration.AgreementsCache(
                    isOn: true,
                    minDays: 1,
                    maxDays: 2
                )

                let user = TestingUser(state: .loggedIn)

                var stub1 = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                stub1.returnData(json: .fromFile("agreements-valid-unaccepted"))
                stub1.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub1)

                var stub2 = NetworkStub(path: .path(Router.acceptAgreements(userID: user.id!).path))
                stub2.returnData(json: .fromFile("agreements-accept-valid"))
                stub2.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub2)

                var before = false
                var after = false
                user.agreements.status { before = try! $0.materialize() }
                expect(before) == false
                user.agreements.accept { _ in }
                user.agreements.status { after = try! $0.materialize() }
                expect(after) == true
                expect(Networking.testingProxy.callCount) == 2
            }
        }
    }
}
