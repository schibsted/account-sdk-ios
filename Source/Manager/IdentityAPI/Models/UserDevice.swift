//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 The user device data.

 SeeAlso: https://techdocs.spid.no/types/device-fingerprint/
 */
public struct UserDevice: JSONParsable {
    ///
    private var hash: String?
    private var deviceId: String?
    private var applicationName: String?
    private var applicationVersion: String?
    private var platform: String?
    ///
    public init(
        hash: String? = nil,
        applicationName: String? = nil,
        applicationVersion: String? = nil
    ) {
        self.hash = hash
        self.deviceId = UIDevice.current.identifierForVendor!.uuidString
        self.platform = UIDevice.current.deviceModel
        self.applicationName = applicationName
        self.applicationVersion = applicationVersion
    }

    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")
        self.hash = try data.string(for: "hash")

    }
}

extension UserDevice: CustomStringConvertible {
    /// human-readable string representation (YAML)
    public var description: String {
        var desc = "UserDevice:\n"
        desc = desc.appendingFormat("  hash: %@\n", self.hash ?? "null")

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
            ].compactedValues()
    }
}
