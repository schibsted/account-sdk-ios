//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Gives you the status of an identifier
 */
public struct IdentifierStatus: Equatable {
    /// If identifier has been verified by user (eg validated auth code/one time code)
    public let verified: Bool

    /// If the identifier exists in any for within the system
    public let exists: Bool

    /// If the identifier is up for grabs (ie has not been verified)
    public let available: Bool

    init(verified: Bool, exists: Bool, available: Bool) {
        self.exists = exists
        self.available = available
        self.verified = verified
    }
}

extension IdentifierStatus: JSONParsable {
    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")
        self.init(
            verified: (try? data.boolean(for: "verified")) ?? false,
            exists: (try? data.boolean(for: "exists")) ?? false,
            available: (try? data.boolean(for: "available")) ?? false
        )
    }
}
