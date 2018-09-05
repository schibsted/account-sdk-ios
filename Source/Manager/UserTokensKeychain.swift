//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/*
    == Keychain JSON structure ==
    {
        // deprecated keys
        access_token: <string>
        refresh_token: <string>
        id_token: <string>
        legacy_user_id: <string>

        // -----------------
        // The above 4 tokens can be replaced with the below structures eventually. But since current
        // clients (as of sdk version 0.14.0) load a user based on the above keys, we can't delete them
        // just yet.
        // -----------------

        "logged_in_users": {
            <access_token>: { refresh_token: <string>, id_token: <string>, user_id: <string> }
            <access_token>: { refresh_token: <string>, id_token: <string>, user_id: <string> }
            .
            .
            <access_token>: { refresh_token: <string>, id_token: <string>, user_id: <string> }
        }
 */

class UserTokensKeychain: KeychainGenericPasswordType {
    struct Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let idToken = "id_token"
        static let legacyUserID = "legacy_user_id"
        static let loggedInUsers = "logged_in_users"
        static let userID = "user_id"
    }

    var fetchedData = [String: Any]()
    var dataToStore: [String: Any] {
        return self.fetchedData
    }
    let accountName = "SchibstedID"

    func data() -> [TokenData] {
        guard let loggedInUsers = (try? self.fetchedData.jsonObject(for: Keys.loggedInUsers)) as? [String: JSONObject] else {
            log(level: .debug, from: self, "no logged in users in \(self.fetchedData)")
            return []
        }
        let data = loggedInUsers.map { (arg) -> TokenData in
            let (accessToken, jsonTokens) = arg
            let refreshToken = try? jsonTokens.string(for: Keys.refreshToken)
            let idToken = try? jsonTokens.string(for: Keys.idToken)
            let userID = try? jsonTokens.string(for: Keys.userID)
            return TokenData(
                accessToken: accessToken,
                refreshToken: refreshToken,
                idToken: try? IDToken(string: idToken ?? ""),
                userID: userID
            )
        }
        log(level: .debug, from: self, "logged in users data: \(data)")
        return data
    }

    func addTokens(_ tokens: TokenData) {
        var loggedInUsers = (try? self.fetchedData.jsonObject(for: Keys.loggedInUsers)) ?? [:]
        loggedInUsers[tokens.accessToken] = [
            Keys.refreshToken: tokens.refreshToken,
            Keys.idToken: tokens.idToken?.string ?? nil,
            Keys.userID: tokens.userID,
        ].compactedValues()

        self.fetchedData[Keys.loggedInUsers] = loggedInUsers
    }

    func removeTokens(forAccessToken accessToken: String) {
        guard var loggedInUsers = try? self.fetchedData.jsonObject(for: Keys.loggedInUsers) else {
            return
        }
        loggedInUsers[accessToken] = nil
        self.fetchedData[Keys.loggedInUsers] = loggedInUsers
    }

    func removeAllTokens() {
        self.fetchedData[Keys.loggedInUsers] = nil
    }

    private func migrate() throws {
        guard let accessToken = try? self.fetchedData.string(for: Keys.accessToken) else {
            return
        }
        let refreshToken = try? self.fetchedData.string(for: Keys.refreshToken)
        let idToken = try? self.fetchedData.string(for: Keys.idToken)
        let userID = try? self.fetchedData.string(for: Keys.legacyUserID) // key deliberately different here for backwards compat
        let tokens = TokenData(
            accessToken: accessToken,
            refreshToken: refreshToken,
            idToken: try? IDToken(string: idToken ?? ""),
            userID: userID
        )

        self.fetchedData[Keys.accessToken] = nil
        self.fetchedData[Keys.refreshToken] = nil
        self.fetchedData[Keys.idToken] = nil
        self.fetchedData[Keys.legacyUserID] = nil

        self.addTokens(tokens)
        try self.saveInKeychain()
    }

    init() {
        var downcastedSelf = self
        if (try? downcastedSelf.fetchFromKeychain()) != nil {
            self.fetchedData = downcastedSelf.fetchedData
            try? self.migrate()
        }
    }
}
