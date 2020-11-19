//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class SecondaryButton: PrimaryButton {
    override func applyTheme(theme: IdentityUITheme) {
        applyTheme(
            normalColor: theme.colors.secondaryButton,
            pressedColor: theme.colors.secondaryButtonPressed,
            disabledColor: theme.colors.secondaryButtonDisabled,
            textColor: theme.colors.secondaryButtonText,
            theme: theme
        )
    }
}
