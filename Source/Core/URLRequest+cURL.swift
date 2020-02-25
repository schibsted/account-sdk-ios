//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension URLRequest {
    var cURLRepresentation: String {
        var components = ["curl -i"]

        guard let url = self.url, url.host != nil else {
            return "curl command could not be created from \(self)"
        }

        if let httpMethod = self.httpMethod?.uppercased() {
            components.append("-X \(httpMethod)")
        }

        for (key, value) in allHTTPHeaderFields ?? [:] {
            switch key.uppercased() {
            case "COOKIE":
                continue
            default:
                components.append("-H \"\(key): \(value)\"")
            }
        }

        if let body = httpBody, let bodyData = String(data: body, encoding: .utf8) {
            let escapedBodyData = bodyData.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-d \"\(escapedBodyData)\"")
        }

        components.append("\"\(url.absoluteString)\"")

        return components.joined(separator: " \\\n\t")
    }
}
