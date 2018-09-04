//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class Checkbox: UIButton, Themeable {
    var theme: IdentityUITheme?

    private var stateColor: UIColor {
        guard let theme = self.theme else { return UIColor.red }
        return self.isChecked ? theme.colors.checkedBox : theme.colors.uncheckedBox
    }

    func applyTheme(theme: IdentityUITheme) {
        self.theme = theme
        self.heightAnchor.constraint(equalToConstant: 26).isActive = true
        self.widthAnchor.constraint(equalToConstant: 26).isActive = true
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setImage(theme.icons.checkedBox, for: .selected)
        self.setImage(theme.icons.uncheckedBox, for: .normal)
        self.setTitle(nil, for: UIControl.State.normal)
        self.tintColor = self.stateColor
        self.imageView?.contentMode = .scaleAspectFit
        self.addTarget(self, action: #selector(self.tap), for: .touchUpInside)
    }

    @objc func tap() {
        self.isSelected = !self.isSelected
        self.tintColor = self.stateColor
        self.sendActions(for: .valueChanged)
    }

    var isChecked: Bool {
        get {
            return self.isSelected
        }
        set {
            self.isSelected = newValue
        }
    }
}
