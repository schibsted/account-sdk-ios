//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 A list of user assets.

 SeeAlso: https://techdocs.spid.no/endpoints/GET/user/%7Bid%7D/assets/
 */
public struct UserAssets: JSONParsable {
    ///
    public let assets: [UserAsset]?
    
    init(from json: JSONObject) throws {
        
        if let assetArray = try? json.jsonArray(of: JSONObject.self, for: "data"), assetArray.count > 0 {
            self.assets = assetArray.compactMap { try? UserAsset(from: $0) }
        } else {
            self.assets = nil
        }
    }
}

extension UserAssets: CustomStringConvertible {
    /// human-readable string representation (YAML)
    public var description: String {
        var desc = "UserAssets:\n"
        desc = desc.appendingFormat("  assets: %@\n", self.assets ?? "null")
        return desc
    }
}
