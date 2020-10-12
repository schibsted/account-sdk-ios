//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//
import UIKit

class Heading: UILabel, Themeable {
    func applyTheme(theme: IdentityUITheme) {
        font = theme.fonts.heading
        numberOfLines = 2
    }
}
