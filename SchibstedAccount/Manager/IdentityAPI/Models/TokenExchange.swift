//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

struct TokenExchange: JSONParsable {
    let code: String

    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")
        let code = try data.string(for: "code")

        self.code = code
    }
}
