//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class ErrorLabel: NormalLabel {
    override func applyTheme(theme: IdentityUITheme) {
        super.applyTheme(theme: theme)
        self.textColor = theme.colors.errorText
        self.font = theme.fonts.error
        self.numberOfLines = 0
    }
}
