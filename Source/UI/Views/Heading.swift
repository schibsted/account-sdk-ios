//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class Heading: UILabel, Themeable {
    func applyTheme(theme: IdentityUITheme) {
        font = theme.fonts.heading
        numberOfLines = 2
    }
}
