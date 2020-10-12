//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import UIKit

protocol DeviceInfo {
    var deviceModel: String { get }
    var systemName: String { get }
    var systemVersion: String { get }
}

struct UserAgent {
    let value: String

    init(sdkVersion: String = sdkVersion, deviceInfo: DeviceInfo = UIDevice.current) {
        value = "SchibstedAccountSDK/\(sdkVersion) (\(deviceInfo.deviceModel); \(deviceInfo.systemName) \(deviceInfo.systemVersion))"
    }
}

extension UIDevice: DeviceInfo {
    var deviceModel: String {
        return model
    }
}
