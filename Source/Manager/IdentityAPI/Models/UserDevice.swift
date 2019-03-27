//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 The user device data.

 SeeAlso: ?
 */
public struct UserDevice: JSONParsable {
    ///
    public var hash: String?
    private var deviceId: String?
    public var applicationName: String?
    public var applicationVersion: String?
    public var platform: String?
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
