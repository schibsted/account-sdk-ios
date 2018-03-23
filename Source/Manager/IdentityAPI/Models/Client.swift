//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

enum ClientRequiredFieldsKey: String {
    case names
    case birthday
    case displayName
}

//
// This is actually not used right now, but we keep it here so that
// when a new RequiredField is added, you are forced to add a new
// ClientRequiredFieldsKey as well
//
private extension RequiredField {
    var clientKey: ClientRequiredFieldsKey {
        switch self {
        case .birthday:
            return .birthday
        case .familyName, .givenName:
            return .names
        case .displayName:
            return .displayName
        }
    }
}

struct Client: JSONParsable {
    var requiredFields: [RequiredField] = []

    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")
        let fields = try data.jsonObject(for: "fields")

        for stringKey in fields.keys where try fields.boolean(for: stringKey) {
            guard let clientKey = ClientRequiredFieldsKey(rawValue: stringKey) else {
                continue
            }
            switch clientKey {
            case .names:
                self.requiredFields.append(.givenName)
                self.requiredFields.append(.familyName)
            case .birthday:
                self.requiredFields.append(.birthday)
            case .displayName:
                self.requiredFields.append(.displayName)
            }
        }
    }
}
