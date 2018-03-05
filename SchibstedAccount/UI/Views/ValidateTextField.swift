//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class ValidateTextField: TextField {
    private var bottomBorder: UIView?

    var isError = false {
        didSet {
            if isError {
                bottomBorder?.backgroundColor = theme?.colors.errorBorder
            } else {
                bottomBorder?.backgroundColor = theme?.colors.textInputBorder
            }
        }
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                bottomBorder?.backgroundColor = theme?.colors.textInputBorderActive
            } else {
                bottomBorder?.backgroundColor = theme?.colors.textInputBorder
            }
        }
    }

    override func applyTheme(theme: IdentityUITheme) {
        self.theme = theme
        self.font = theme.fonts.normal
        // cursor color
        self.tintColor = theme.colors.textInputCursor
        self.clearButtonMode = .never
        self.applyUnfocusedStyle()

        if self.bottomBorder == nil {
            self.borderStyle = .none
            self.translatesAutoresizingMaskIntoConstraints = false

            let border = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            border.backgroundColor = theme.colors.textInputBorder
            border.translatesAutoresizingMaskIntoConstraints = false

            addSubview(border)

            border.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            border.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            border.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            border.heightAnchor.constraint(equalToConstant: 1).isActive = true

            self.bottomBorder = border
        }
    }
}
