//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

struct IDToken {
    let string: String
    let subjectID: String
    let legacyUserID: String?

    // SE-0189
    public init(string: String, subjectID: String, legacyUserID: String?) {
        self.string = string
        self.subjectID = subjectID
        self.legacyUserID = legacyUserID
    }

    init(string: String) throws {
        self.string = string
        let json = try JWTHelper.toJSON(string: string)
        self.subjectID = try json.string(for: "sub")
        self.legacyUserID = try? json.string(for: "legacyUserId")
    }
}

extension IDToken {
    var data: Data? {
        return self.string.data(using: .utf8)
    }
}

extension IDToken: CustomStringConvertible {
    var description: String {
        return self.string
    }
}

extension IDToken: Equatable {
    static func == (lhs: IDToken, rhs: IDToken) -> Bool {
        return lhs.data == rhs.data
    }
}
