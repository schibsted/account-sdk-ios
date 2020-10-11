//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

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

/**
 A user asset data.

 SeeAlso: https://techdocs.login.schibsted.com/endpoints/GET/user/%7Bid%7D/asset/%7BassetId%7D/
 */
public struct UserAsset: JSONParsable {
    /// Asset identifier
    public let id: String?
    /// Asset access current status
    public let status: AccessStatus?
    /// The time the access was last updated
    public let updatedAt: Date?
    /// The time the access was created
    public let createdAt: Date?

    init(from json: JSONObject) throws {
        id = try? json.string(for: "assetId")

        status = json.accessStatus(for: "status")

        updatedAt = json.date(for: "updated")
        createdAt = json.date(for: "created")
    }
}

extension UserAsset: CustomStringConvertible {
    /// human-readable string representation (YAML)
    public var description: String {
        var desc = "UserAsset:\n"
        desc = desc.appendingFormat("  id: %@\n", id ?? "null")
        desc = desc.appendingFormat("  status: %@\n", status?.description ?? "null")
        desc = desc.appendingFormat("  updatedAt: %@\n", updatedAt?.description ?? "null")
        desc = desc.appendingFormat("  createdAt: %@\n", createdAt?.description ?? "null")
        return desc
    }
}

private extension JSONObjectProtocol where Key == String, Value == Any {
    func date(for key: Key) -> Date? {
        guard let value = try? string(for: key) else {
            return nil
        }

        return DateFormatter.local.date(from: value)
    }

    func accessStatus(for key: Key) -> AccessStatus? {
        guard let value = try? string(for: key), let status = Int(value) else {
            return nil
        }

        return AccessStatus(rawValue: status)
    }
}

private extension DateFormatter {
    static let local: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
