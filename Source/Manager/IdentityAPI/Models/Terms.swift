//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
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

 - SeeAlso: [SPiD selfservice](http://techdocs.spid.no/selfservice/access/)
 */
public struct Terms: JSONParsable {
    ///
    public let platformPrivacyURL: URL?
    ///
    public let platformTermsURL: URL?
    ///
    public let clientPrivacyURL: URL?
    ///
    public let clientTermsURL: URL?
    ///
    public let terms: String?
    ///
    public let summary: String?

    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")
        self.platformPrivacyURL = URL(string: try? data.string(for: "platform_privacy_url"))
        self.platformTermsURL = URL(string: try? data.string(for: "platform_terms_url"))
        self.clientPrivacyURL = URL(string: try? data.string(for: "privacy_url"))
        self.clientTermsURL = URL(string: try? data.string(for: "terms_url"))
        self.terms = try? data.string(for: "terms")

        if let summaryArray = try? data.jsonArray(of: String.self, for: "summary"), summaryArray.count > 0 {
            self.summary = summaryArray.joined()
        } else {
            self.summary = nil
        }
    }
}
