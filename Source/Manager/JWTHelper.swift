//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

enum JWTHelperError: Error {
    case invalidString(String)
    case componentDecodingError(String)
}

extension JWTHelperError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .invalidString(string):
            return "Got invalid jwt string: \(string.shortened)"
        case let .componentDecodingError(component):
            return "Could not decode component: \(component.shortened)"
        }
    }
}

extension JWTHelperError: ClientErrorConvertible {
    var clientError: ClientError {
        return .unexpected(self)
    }
}

protocol JWTHelperProxy {
    func toJSON(string: String) throws -> JSONObject
}

struct DefaultJWTHelperProxy: JWTHelperProxy {
    func toJSON(string: String) throws -> JSONObject {
        guard case let components = string.components(separatedBy: "."), components.count == 3 else {
            throw JWTHelperError.invalidString(string)
        }

        var component = components[1]
        if case let remainder = component.count % 4, remainder != 0 {
            component = component.padding(toLength: component.count + remainder, withPad: "=", startingAt: 0)
        }

        guard let decodedData = Data(base64Encoded: component, options: NSData.Base64DecodingOptions()) else {
            throw JWTHelperError.componentDecodingError(component)
        }

        return try decodedData.jsonObject()
    }
}

struct JWTHelper {
    static var proxy: JWTHelperProxy = DefaultJWTHelperProxy()

    static func toJSON(string: String) throws -> JSONObject {
        return try JWTHelper.proxy.toJSON(string: string)
    }
}
