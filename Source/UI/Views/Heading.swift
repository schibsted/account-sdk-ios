//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class Heading: UILabel, Themeable {
    func applyTheme(theme: IdentityUITheme) {
        self.font = theme.fonts.heading
        self.numberOfLines = 2
    }
}
