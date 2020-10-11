//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension Networking {
    enum Header: String {
        case contentType = "Content-Type"
        case authorization = "Authorization"
        case contentLength = "Content-Length"
        case userAgent = "User-Agent"
        case xSchibstedAccountUserAgent = "X-Schibsted-Account-User-Agent"
        case xOIDC = "X-OIDC"
        case sdkType = "SDK-Type"
        case sdkVersion = "SDK-Version"
        case pulseJWE = "pulse-jwe"
    }
}

extension URLRequest {
    mutating func setValue(_ value: String, for header: Networking.Header) {
        setValue(value, forHTTPHeaderField: header.rawValue)
    }
}
