//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

struct GenericError {
    private init() {}
}

extension GenericError {
    struct Unexpected: Error {
        var string: String?
        init(_ string: String) {
            self.string = string
        }
    }
}

extension GenericError.Unexpected: CustomStringConvertible {
    var description: String {
        if let string = self.string {
            return "\(type(of: self))! \(string)"
        }
        return "\(type(of: self))!"
    }
}

extension GenericError {
    struct WTF: Error {
        var string: String?
        init(_ string: String) {
            self.string = string
        }
    }
}

extension GenericError.WTF: CustomStringConvertible {
    var description: String {
        if let string = self.string {
            return "\(type(of: self))! \(string)"
        }
        return "\(type(of: self))!"
    }
}
