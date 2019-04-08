//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 The user device data.

 SeeAlso: https://techdocs.spid.no/types/device-fingerprint/
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
        self.hash = try data.string(for: "hash")
    }
}

extension UserDeviceHash: CustomStringConvertible {
    /// human-readable string representation (YAML)
    public var description: String {
        var desc = "UserDeviceHash:\n"
        desc = desc.appendingFormat("  hash: %@\n", self.hash ?? "null")

        return desc
    }
}
