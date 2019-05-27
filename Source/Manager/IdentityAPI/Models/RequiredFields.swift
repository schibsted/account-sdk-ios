//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 The fields that may be set as required by your client. You can set these under the configuration
 section of [Schibsted account Self Service](https://techdocs.login.schibsted.com/selfservice/access/)
 */
public enum RequiredField: String {
    ///
    case givenName = "name.given_name"
    ///
    case familyName = "name.family_name"
    ///
    case birthday
    ///
    case displayName = "display_name"
    ///
    case phoneNumber = "phone_number"
}

struct RequiredFields: JSONParsable {
    let fields: [RequiredField]

    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")
        let fields = try data.jsonArray(of: String.self, for: "requiredFields")
        var allTheFields: [RequiredField] = []
        for fieldString in fields {
            if let rf = RequiredField(rawValue: fieldString) {
                allTheFields.append(rf)
            }
        }

        self.fields = allTheFields
    }
}
