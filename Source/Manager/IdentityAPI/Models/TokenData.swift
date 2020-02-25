//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

struct TokenData: JSONParsable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let idToken: IDToken?
    let userID: String?

    init(accessToken: String, refreshToken: String?, idToken: IDToken?, userID: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        // Try set user ID from idtoken first
        if let idToken = self.idToken, let legacyUserID = idToken.legacyUserID {
            self.userID = legacyUserID
        } else {
            self.userID = userID
        }
    }

    init(from json: JSONObject) throws {
        self.init(
            accessToken: try json.string(for: "access_token"),
            refreshToken: try? json.string(for: "refresh_token"),
            idToken: try? IDToken(string: (try? json.string(for: "id_token")) ?? ""),
            userID: try? json.string(for: "user_id")
        )
    }
}

extension TokenData: CustomStringConvertible {
    var description: String {
        return "<"
            + "access:\(accessToken.shortened), "
            + "refresh:\(refreshToken?.shortened ?? ""), "
            + "id:\(String(describing: idToken).shortened), "
            + "userID:\(userID?.shortened ?? "")"
            + ">"
    }
}
