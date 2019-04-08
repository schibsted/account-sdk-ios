//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension TokenData {
    var anyUserID: String? {
        // Prioritize the subject ID in the idtoken
        return self.idToken?.subjectID ?? self.userID
    }
}
