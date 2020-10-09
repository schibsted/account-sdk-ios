//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

open class SPiDAccessToken: Codable {
    open var userID: String
    open var accessToken: String?
    open var expiresAt: Date
    open var refreshToken: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case refreshToken = "refresh_token"
    }

    public init!(userID: String, accessToken: String?, expiresAt: Date?, refreshToken: String) {
        guard let accessToken = accessToken, let expiresAt = expiresAt else {
            return nil
        }

        self.userID = userID
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }

    public convenience init!(dictionary: [String: Any]) {
        guard let userID = dictionary[CodingKeys.userId.rawValue] as? String,
              let accessToken = dictionary[CodingKeys.accessToken.rawValue] as? String,
              let expiresIn = dictionary[CodingKeys.expiresIn.rawValue] as? NSNumber,
              let refreshToken = dictionary[CodingKeys.refreshToken.rawValue] as? String else {
            return nil
        }

        self.init(userID: userID,
                  accessToken: accessToken,
                  expiresAt: Date(timeIntervalSinceNow: TimeInterval(expiresIn.intValue)),
                  refreshToken: refreshToken)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userID = try container.decode(String.self, forKey: .userId)
        self.accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken)
        self.expiresAt = try container.decode(Date.self, forKey: .expiresAt)
        self.refreshToken = try container.decode(String.self, forKey: .refreshToken)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userId)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(expiresAt, forKey: .expiresAt)
        try container.encode(refreshToken, forKey: .refreshToken)
    }

    public func hasExpired() -> Bool {
        return min(Date(), expiresAt) == expiresAt
    }

    public func isClientToken() -> Bool {
        return userID == "0"
    }
}
