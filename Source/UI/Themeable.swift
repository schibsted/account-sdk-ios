//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

protocol Themeable: AnyObject {
    func applyTheme(theme: IdentityUITheme)
}
