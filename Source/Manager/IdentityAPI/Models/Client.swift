//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

enum ClientRequiredFieldsKey: String {
    case names
    case birthday
    case displayName
    case phoneNumber
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
        case .phoneNumber:
            return .phoneNumber
        }
    }
}

/// Represents a client in [Schibsted account Self Service](http://techdocs.spid.no/selfservice/access/)
public struct Client: JSONParsable {
    /// Which fields are required by your client
    public var requiredFields: [RequiredField] = []

    /// Your merchant ID
    public let merchantID: String?

    /// Your merchant name
    public let merchantName: String?

    ///
    public enum Kind: String {
        /// internal schibsted client
        case `internal`
        /// 3rd party client
        case external
    }

    /// What kind of client are your (internal or 3rd party)
    public let kind: Kind?

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
            case .phoneNumber:
                self.requiredFields.append(.phoneNumber)
            }
        }

        if let merchantID = try? data.number(for: "merchantId") {
            self.merchantID = String(describing: Int(merchantID))
        } else {
            self.merchantID = nil
        }

        let merchantData = (try? data.jsonObject(for: "merchant")) ?? [:]
        self.merchantName = try? merchantData.string(for: "name")
        if let kindValue = try? merchantData.string(for: "type") {
            self.kind = Kind(rawValue: kindValue)
        } else {
            self.kind = nil
        }
    }
}
