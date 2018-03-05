//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

extension Networking {
    static var testingProxy: TestingNetworkingProxy {
        return self.proxy as! TestingNetworkingProxy
    }
}

class SchibstedAccountConfiguration: QuickConfiguration {
    override class func configure(_ configuration: Configuration) {
        configuration.beforeSuite {
            Logger.shared.removeTransports()
        }
        configuration.beforeEach {
            expect(OwnedTaskHandle.counter.value).to(equal(0))

            Utils.cleanupKeychain()
            PasswordlessTokenStore.clear()
            Networking.proxy = TestingNetworkingProxy()
            JWTHelper.proxy = TestingJWTHelperProxy()

            // The simulator example app creates a user on start up so this can be potentially 1 before anything runs
            User.globalStore.removeAll()
        }
        configuration.afterEach {
            Utils.cleanupKeychain()
            PasswordlessTokenStore.clear()

            expect(User.globalStore.count) == 0

            OwnedTaskHandle.counter.value = 0

            expect(AutoRefreshURLProtocol.userTaskManagerMap.count) == 0
            expect(TaskOperation.counter.value).toEventually(equal(0))
            expect(AutoRefreshURLProtocol.counter.value).toEventually(equal(0))
            expect(AutoRefreshTask.counter.value) == 0

            TaskOperation.counter.value = 0
            AutoRefreshURLProtocol.counter.value = 0
            AutoRefreshTask.counter.value = 0
        }
    }
}
