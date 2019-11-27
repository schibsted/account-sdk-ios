//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 The user device data.

 SeeAlso: https://techdocs.login.schibsted.com/types/device-fingerprint/
 */
public struct UserDeviceHash: JSONParsable {
    ///
    private var hash: String?

    ///
    public init(hash: String? = nil) {
        self.hash = hash
    }

    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")
        hash = try data.string(for: "hash")
    }
}

extension UserDeviceHash: CustomStringConvertible {
    /// human-readable string representation (YAML)
    public var description: String {
        var desc = "UserDeviceHash:\n"
        desc = desc.appendingFormat("  hash: %@\n", hash ?? "null")

        return desc
    }
}
