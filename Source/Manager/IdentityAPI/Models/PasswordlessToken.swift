//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

struct PasswordlessToken {
    let value: String
    init(_ value: String) {
        self.value = value
    }
}

extension PasswordlessToken: JSONParsable {
    init(from json: JSONObject) throws {
        let token = try json.string(for: "passwordless_token")
        self.init(token)
    }
}

extension PasswordlessToken: CustomStringConvertible {
    var description: String {
        return self.value
    }
}

extension PasswordlessToken: Equatable {
    static func == (lhs: PasswordlessToken, rhs: PasswordlessToken) -> Bool {
        return lhs.value == rhs.value
    }
}
