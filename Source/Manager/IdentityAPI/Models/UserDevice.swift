//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import UIKit

/**
 The user device data.

 SeeAlso: https://techdocs.login.schibsted.com/types/device-fingerprint/
 */
public struct UserDevice {
    ///
    private var deviceId: String
    private var applicationName: String
    private var applicationVersion: String
    private var platform: String
    ///
    public init(
        applicationName: String,
        applicationVersion: String
    ) {
        deviceId = UIDevice.current.identifierForVendor!.uuidString
        platform = UIDevice.current.deviceModel
        self.applicationName = applicationName
        self.applicationVersion = applicationVersion
    }
}

extension UserDevice: CustomStringConvertible {
    /// human-readable string representation (YAML)
    public var description: String {
        var desc = "UserDevice:\n"
        desc = desc.appendingFormat("  deviceId: %@\n", deviceId)
        desc = desc.appendingFormat("  applicationName: %@\n", applicationName)
        desc = desc.appendingFormat("  applicationVersion: %@\n", applicationVersion)
        desc = desc.appendingFormat("  platform: %@\n", platform)

        return desc
    }
}

extension UserDevice {
    func formData() -> [String: String] {
        return [
            "deviceId": deviceId,
            "platform": platform,
            "applicationName": applicationName,
            "applicationVersion": applicationVersion,
        ]
    }
}
