//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

struct Agreements: JSONParsable {
    let client: Bool
    let platform: Bool

    init(acceptanceStatus: Bool) {
        client = acceptanceStatus
        platform = acceptanceStatus
    }

    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")
        let agreements = try data.jsonObject(for: "agreements")
        platform = agreements["platform"] as? Bool ?? false
        client = agreements["client"] as? Bool ?? false
    }

    func toJSON() -> JSONObject {
        return [
            "data": [
                "agreements": [
                    "platform": platform,
                    "client": client,
                ],
            ],
        ]
    }
}
