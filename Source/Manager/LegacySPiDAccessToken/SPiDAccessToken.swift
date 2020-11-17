//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

open class SPiDAccessToken: NSObject, NSCoding {
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

    public func encode(with coder: NSCoder) {
        coder.encode(userID, forKey: CodingKeys.userId.rawValue)
        coder.encode(accessToken, forKey: CodingKeys.accessToken.rawValue)
        coder.encode(expiresAt, forKey: CodingKeys.expiresAt.rawValue)
        coder.encode(refreshToken, forKey: CodingKeys.refreshToken.rawValue)
    }
    
    public required init?(coder: NSCoder) {
        guard let userID = coder.decodeObject(forKey: CodingKeys.userId.rawValue) as? String,
              let accessToken = coder.decodeObject(forKey: CodingKeys.accessToken.rawValue) as? String,
              let expiresAt = coder.decodeObject(forKey: CodingKeys.expiresAt.rawValue) as? Date,
              let refreshToken = coder.decodeObject(forKey: CodingKeys.refreshToken.rawValue) as? String
              else {
                return nil
              }

        self.userID = userID
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }

    public func hasExpired() -> Bool {
        return min(Date(), expiresAt) == expiresAt
    }

    public func isClientToken() -> Bool {
        return userID == "0"
    }
}
