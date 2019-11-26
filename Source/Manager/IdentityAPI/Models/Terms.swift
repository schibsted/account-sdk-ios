//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

private extension URL {
    init?(string: String?) {
        guard let string = string else {
            return nil
        }
        self.init(string: string)
    }
}

/**
 The links and data that are associated with the terms and conditions for your client

 - SeeAlso: [Schibsted account Self Service](https://techdocs.login.schibsted.com/selfservice/access/)
 */
public struct Terms: JSONParsable {
    ///
    public let platformPrivacyURL: URL?
    ///
    public let platformTermsURL: URL?
    ///
    public let platformTermsText: String?
    ///
    public let clientPrivacyURL: URL?
    ///
    public let clientTermsURL: URL?
    ///
    public let summary: String?

    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")
        platformPrivacyURL = URL(string: try? data.string(for: "platform_privacy_url"))
        platformTermsURL = URL(string: try? data.string(for: "platform_terms_url"))
        platformTermsText = try? data.string(for: "terms")
        clientPrivacyURL = URL(string: try? data.string(for: "privacy_url"))
        clientTermsURL = URL(string: try? data.string(for: "terms_url"))

        if let summaryArray = try? data.jsonArray(of: String.self, for: "summary"), summaryArray.count > 0 {
            summary = summaryArray.joined()
        } else {
            summary = nil
        }
    }
}
