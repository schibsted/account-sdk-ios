//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension String {
    var shortened: String {
        let maxChars = 8
        let charsOnEachSide = 3
        let inbetweenChar: Character = "."

        if count <= charsOnEachSide * 2 {
            return self
        }

        return self[..<index(startIndex, offsetBy: charsOnEachSide)]
            + String(repeating: String(inbetweenChar), count: maxChars - charsOnEachSide * 2)
            + self[index(endIndex, offsetBy: -charsOnEachSide)...]
    }
}
