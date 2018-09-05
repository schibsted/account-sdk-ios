//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension Data {
    func jsonObject() throws -> JSONObject {
        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions())
        } catch {
            throw JSONError.parse(error)
        }
        guard let unwrappedJson = json as? JSONObject else {
            throw JSONError.parse(GenericError.Unexpected("JSONSerialization.jsonObject as? JSONObject failed"))
        }
        return unwrappedJson
    }
}
