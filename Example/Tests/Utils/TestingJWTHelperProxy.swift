//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
@testable import SchibstedAccount

struct TestingJWTHelperProxy: JWTHelperProxy {
    //
    // For testing purposes we don't care about JWT format. We just use normal JSON. And if it's just a string
    // we return that as the "jwt sub" field so that IDToken can get set with it
    //
    func toJSON(string: String) throws -> JSONObject {
        guard let data = string.data(using: .utf8), let json = try? data.jsonObject() else {
            return [
                "sub": string,
            ]
        }
        return json
    }
}
