//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

enum JSONError: Error {
    case noKey(String)
    case parse(Error)
    case notString(String)
    case notJSONObject(String)
    case notNumber(String)
    case notBoolean(String)
    case notArrayOf(String, forKey: String)
}

extension JSONError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .noKey(key):
            return "Did not find key \(key)"
        case let .parse(error):
            return "JSON error: \(error)"
        case let .notString(key):
            return "Key \(key) was not convertible to string"
        case let .notJSONObject(key):
            return "Key \(key) was not convertible to JSON object"
        case let .notNumber(key):
            return "Key \(key) was not convertible to number"
        case let .notBoolean(key):
            return "Key \(key) was not convertible to boolean"
        case let .notArrayOf(type, key):
            return "Key \(key) was not convertible to Array<\(type)>"
        }
    }
}
