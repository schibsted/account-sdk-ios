//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class NormalLabel: UILabel, Themeable {
    func applyTheme(theme: IdentityUITheme) {
        font = theme.fonts.normal
        textColor = theme.colors.normalText
    }
}
