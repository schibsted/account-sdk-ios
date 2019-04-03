//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 The user device data.

 SeeAlso: https://techdocs.spid.no/types/device-fingerprint/
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
        self.deviceId = UIDevice.current.identifierForVendor!.uuidString
        self.platform = UIDevice.current.deviceModel
        self.applicationName = applicationName
        self.applicationVersion = applicationVersion
    }
}

extension UserDevice: CustomStringConvertible {
    /// human-readable string representation (YAML)
    public var description: String {
        var desc = "UserDevice:\n"
        desc = desc.appendingFormat("  deviceId: %@\n", self.deviceId)
        desc = desc.appendingFormat("  applicationName: %@\n", self.applicationName)
        desc = desc.appendingFormat("  applicationVersion: %@\n", self.applicationVersion)
        desc = desc.appendingFormat("  platform: %@\n", self.platform )


        return desc
    }
}

extension UserDevice {
    func formData() -> [String: String] {
        return [
            "deviceId": self.deviceId,
            "platform": self.platform,
            "applicationName": self.applicationName,
            "applicationVersion": self.applicationVersion,
            ]
    }
}
