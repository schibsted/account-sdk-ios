//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

/**
 A list of user assets.

 SeeAlso: https://techdocs.login.schibsted.com/endpoints/GET/user/%7Bid%7D/assets/
 */
struct UserAssets: JSONParsable {
    ///
    let assets: [UserAsset]

    init(from json: JSONObject) throws {
        let assetArray = try json.jsonArray(of: JSONObject.self, for: "data")
        assets = assetArray.compactOrFlatMap { try? UserAsset(from: $0) }
    }
}

extension UserAssets: CustomStringConvertible {
    /// human-readable string representation (YAML)
    public var description: String {
        var desc = "UserAssets:\n"
        desc = desc.appendingFormat("  assets: %@\n", assets)
        return desc
    }
}
