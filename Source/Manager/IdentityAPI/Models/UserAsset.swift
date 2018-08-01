//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

/**
 A user asset data.

 SeeAlso: https://techdocs.spid.no/endpoints/GET/user/%7Bid%7D/asset/%7BassetId%7D/
 */
public struct UserAsset: JSONParsable {
    ///
    public enum AccessStatus: Int {
        ///
        case deleted = 0
        ///
        case active
        
        ///
        public var description: String {
            switch self {
            case .deleted: return "Deleted"
            case .active: return "Active"
            }
        }
    }
    
    /// The ID of the merchant the client belongs to
    public var merchantID: Int?
    /// User identifier
    public var uuid: String?
    /// User identifier
    public var userID: Int?
    /// Asset identifier
    public var assetID: String?
    /// Asset access current status
    public var status: AccessStatus?
    /// The time the access was last updated
    public var updated: Date?
    /// The time the access was created
    public var created: Date?
    
    init(from json: JSONObject) throws {
        if let value = try? json.string(for: "merchantId"), let merchantID = Int(value) {  // integer (as string)
            self.merchantID = merchantID
        }
        
        self.uuid = try? json.string(for: "uuid")
        if let value = try? json.string(for: "userId"), let userID = Int(value) { // integer (as string)
            self.userID = userID
        }
        
        self.assetID = try? json.string(for: "assetId")
        if let value = try? json.string(for: "status"), let status = Int(value) {
            self.status = AccessStatus(rawValue: Int(status))
        } else {
            self.status = nil
        }
        
        if let updated = try? json.string(for: "updated") {
            self.updated = DateFormatter.local.date(from: updated)
        }
        
        if let created = try? json.string(for: "created") {
            self.created = DateFormatter.local.date(from: created)
        }
    }
}

extension UserAsset: CustomStringConvertible {
    /// human-readable string representation (YAML)
    public var description: String {
        var desc = "UserAsset:\n"
        desc = desc.appendingFormat("  merchantID: %@\n", self.merchantID?.description ?? "null")
        desc = desc.appendingFormat("  uuid: %@\n", self.uuid ?? "null")
        desc = desc.appendingFormat("  userID: %@\n", self.userID?.description ?? "null")
        desc = desc.appendingFormat("  assetID: %@\n", self.assetID ?? "null")
        desc = desc.appendingFormat("  status: %@\n", self.status?.description ?? "null")
        desc = desc.appendingFormat("  updated: %@\n", self.updated?.description ?? "null")
        desc = desc.appendingFormat("  created: %@\n", self.created?.description ?? "null")
        return desc
    }
}

private extension DateFormatter {
    static let local: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
