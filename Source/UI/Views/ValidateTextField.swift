//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import UIKit

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
        font = theme.fonts.normal
        // cursor color
        tintColor = theme.colors.textInputCursor
        clearButtonMode = .never
        applyUnfocusedStyle()

        if bottomBorder == nil {
            borderStyle = .none
            translatesAutoresizingMaskIntoConstraints = false

            let border = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            border.backgroundColor = theme.colors.textInputBorder
            border.translatesAutoresizingMaskIntoConstraints = false

            addSubview(border)

            border.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            border.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            border.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            border.heightAnchor.constraint(equalToConstant: 1).isActive = true

            bottomBorder = border
        }
    }
}
