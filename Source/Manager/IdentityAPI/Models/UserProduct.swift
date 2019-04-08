//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 A user product data.

 SeeAlso: https://techdocs.spid.no/endpoints/GET/user/%7BuserId%7D/product/%7BproductId%7D/
 */
public struct UserProduct: JSONParsable {
    ///
    public var productID: String?
    ///
    public var result: Bool?

    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")

        self.productID = try? data.string(for: "productId")
        self.result = try? data.boolean(for: "result")
    }
}

extension UserProduct: CustomStringConvertible {
    /// human-readable string representation (YAML)
    public var description: String {
        var desc = "UserProduct:\n"
        desc = desc.appendingFormat("  productID: %@\n", self.productID ?? "null")
        desc = desc.appendingFormat("  result: %@\n", self.result?.description ?? "null")
        return desc
    }
}
