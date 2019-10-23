//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class InfoLabel: NormalLabel {
    override func applyTheme(theme: IdentityUITheme) {
        super.applyTheme(theme: theme)
        textColor = theme.colors.infoText
        font = theme.fonts.info
    }
}
