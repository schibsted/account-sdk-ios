//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
@testable import SchibstedAccount

private func setTokens(on user: User, id: String) {
    _ = try? user.set(
        accessToken: "testAccessToken",
        refreshToken: "testRefreshToken",
        idToken: IDToken(stringLiteral: id),
        userID: "testLegacyUserID"
    )
}

extension TestingUser {
    convenience init(state: UserState, id: String = "testIDToken") {
        self.init(clientConfiguration: .testing)
        if state == .loggedIn {
            setTokens(on: self.wrapped, id: id)
        }
    }
}

extension User {
    convenience init(state: UserState, id: String = "testIDToken") {
        self.init(clientConfiguration: .testing)
        if state == .loggedIn {
            setTokens(on: self, id: id)
        }
    }
}
