//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
@testable import SchibstedAccount

extension IDToken: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(string: value, subjectID: value, legacyUserID: nil)
    }
}
