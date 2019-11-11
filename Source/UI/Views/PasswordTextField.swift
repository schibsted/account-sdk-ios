import Foundation

class PasswordTextField: TextField {
    override func applyTheme(theme: IdentityUITheme) {
        super.applyTheme(theme: theme)

        let passwordVisibilityView = UIButton(type: .custom)
        passwordVisibilityView.setImage(UIImage.schibstedPasswordShow, for: .normal)
        passwordVisibilityView.frame = CGRect(x: 0, y: 0, width: UIImage.schibstedPasswordShow.size.width + theme.geometry.groupedViewSpacing, height: UIImage.schibstedPasswordShow.size.height)
        passwordVisibilityView.addTarget(self, action: #selector(self.togglePasswordVisibility), for: .touchUpInside)

        self.keyboardType = .default
        self.autocorrectionType = .no

        self.rightView = passwordVisibilityView
        self.rightViewMode = .always

        self.isSecureTextEntry = true

        if #available(iOS 11.0, *) {
            self.textContentType = .password
        }
    }

    @IBAction private func togglePasswordVisibility(passwordVisibility: UIButton) {
        if (self.isSecureTextEntry) {
            passwordVisibility.setImage(UIImage.schibstedPasswordHide, for:.normal)
            self.isSecureTextEntry = false
        } else {
            passwordVisibility.setImage(UIImage.schibstedPasswordShow, for:.normal)
            self.isSecureTextEntry = true
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
