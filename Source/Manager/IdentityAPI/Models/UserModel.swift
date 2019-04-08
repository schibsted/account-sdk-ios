//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

struct UserModel: Equatable {
    let email: String
    init(email: String) {
        self.email = email
    }
}

extension UserModel: JSONParsable {
    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")
        let email = try data.string(for: "email")
        self.init(email: email)
    }
}
