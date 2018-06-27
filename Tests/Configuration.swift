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
        configuration.beforeEach {
            Logger.shared.removeTransports()
            expect(OwnedTaskHandle.counter.value).to(equal(0))

            SDKConfiguration.shared.reset()

            Utils.cleanupKeychain()
            PasswordlessTokenStore.clear()

            //
            // Before each test, make sure we reset the proxy to use the testing networking proxy incase a test changes the configuration
            // And make sure the internal forwarding proxy if the testing proxy is the default one.
            //
            Networking.proxy = TestingNetworkingProxy()
            JWTHelper.proxy = TestingJWTHelperProxy()

            // The simulator example app creates a user on start up so this can be potentially 1 before anything runs
            User.globalStore.removeAll()
        }
        configuration.afterEach {
            Utils.cleanupKeychain()
            PasswordlessTokenStore.clear()

            expect(User.globalStore.count).toEventually(equal(0))

            OwnedTaskHandle.counter.value = 0

            expect(AutoRefreshURLProtocol.userTaskManagerMap.count) == 0
            expect(TaskOperation.counter.value).toEventually(equal(0))
            expect(AutoRefreshURLProtocol.counter.value).toEventually(equal(0))
            expect(AutoRefreshTask.counter.value) == 0

            TaskOperation.counter.value = 0
            AutoRefreshURLProtocol.counter.value = 0
            AutoRefreshTask.counter.value = 0

            StubbedNetworkingProxy.removeStubs()

            Settings.clearAll()
        }
    }
}
