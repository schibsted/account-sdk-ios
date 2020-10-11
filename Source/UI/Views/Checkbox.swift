//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class Checkbox: UIButton, Themeable {
    var theme: IdentityUITheme?

    private var stateColor: UIColor {
        guard let theme = self.theme else { return UIColor.red }
        return isChecked ? theme.colors.checkedBox : theme.colors.uncheckedBox
    }

    func applyTheme(theme: IdentityUITheme) {
        self.theme = theme
        heightAnchor.constraint(equalToConstant: 26).isActive = true
        widthAnchor.constraint(equalToConstant: 26).isActive = true
        translatesAutoresizingMaskIntoConstraints = false
        setImage(theme.icons.checkedBox, for: .selected)
        setImage(theme.icons.uncheckedBox, for: .normal)
        setTitle(nil, for: UIControl.State.normal)
        tintColor = stateColor
        imageView?.contentMode = .scaleAspectFit
        addTarget(self, action: #selector(tap), for: .touchUpInside)
    }

    @objc func tap() {
        isSelected = !isSelected
        tintColor = stateColor
        sendActions(for: .valueChanged)
    }

    var isChecked: Bool {
        get {
            return isSelected
        }
        set {
            isSelected = newValue
        }
    }
}
