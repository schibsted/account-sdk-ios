//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class NormalLabel: UILabel, Themeable {
    func applyTheme(theme: IdentityUITheme) {
        self.font = theme.fonts.normal
        self.textColor = theme.colors.normalText
    }
}
