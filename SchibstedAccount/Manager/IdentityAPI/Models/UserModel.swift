//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

struct UserModel {
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

extension UserModel: Equatable {
    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        return lhs.email == rhs.email
    }
}
