//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import UIKit

class PasswordTextField: TextField {
    override func applyTheme(theme: IdentityUITheme) {
        super.applyTheme(theme: theme)

        let passwordVisibilityView = UIButton(type: .custom)
        if #available(iOS 13.0, *) {
            passwordVisibilityView.tintColor = .label
        }

        passwordVisibilityView.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: theme.geometry.groupedViewSpacing)
        passwordVisibilityView.setImage(UIImage.schibstedPasswordShow, for: .normal)
        passwordVisibilityView.frame = CGRect(x: 0, y: 0, width: 25 + theme.geometry.groupedViewSpacing, height: 25)
        passwordVisibilityView.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)

        keyboardType = .default
        autocorrectionType = .no

        rightView = passwordVisibilityView
        rightViewMode = .always

        isSecureTextEntry = true

        if #available(iOS 11.0, *) {
            self.textContentType = .password
        }
    }

    @IBAction private func togglePasswordVisibility(passwordVisibility: UIButton) {
        if isSecureTextEntry {
            passwordVisibility.setImage(UIImage.schibstedPasswordHide, for: .normal)
            isSecureTextEntry = false
        } else {
            passwordVisibility.setImage(UIImage.schibstedPasswordShow, for: .normal)
            isSecureTextEntry = true
        }
    }

    // from: https://stackoverflow.com/a/43715370
    override var isSecureTextEntry: Bool {
        didSet {
            if isFirstResponder {
                _ = becomeFirstResponder()
            }
        }
    }

    override func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()
        if isSecureTextEntry, let text = self.text {
            self.text?.removeAll()
            insertText(text)
        }

        return success
    }
}
