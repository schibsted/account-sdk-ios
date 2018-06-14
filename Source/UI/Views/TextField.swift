//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class TextField: UITextField, Themeable {
    var theme: IdentityUITheme?

    var enableCursorMotion = true
    var contentInset = UIEdgeInsets()
    private var clearButtonRightSpacing: CGFloat = 0

    fileprivate var clearButton: UIButton?

    private var normalBorderColor: CGColor {
        guard let theme = self.theme else {
            return UIColor.black.cgColor
        }
        return theme.colors.textInputBorder.cgColor
    }

    private var normalBackgroundColor: UIColor {
        guard let theme = self.theme else {
            return UIColor.white
        }
        return theme.colors.textInputBackground
    }

    func applyTheme(theme: IdentityUITheme) {
        self.theme = theme
        self.font = theme.fonts.normal
        self.layer.borderWidth = 1
        self.layer.cornerRadius = theme.geometry.inputViewCornerRadius
        self.textColor = theme.colors.normalText
        // cursor color
        self.tintColor = theme.colors.textInputCursor
        self.contentInset = UIEdgeInsets(
            top: theme.geometry.groupedViewSpacing,
            left: 16,
            bottom: theme.geometry.groupedViewSpacing,
            right: 16
        )

        if self.clearButtonMode == .whileEditing, let clearImage = theme.icons.clearTextInput {
            //
            // Just setting the rightViewMode to .whileEditing seems to not work. The view shows up as soon
            // as the textfield becomes first responder. So we handle the state ourself
            //
            self.clearButtonMode = .never

            self.clearButtonRightSpacing = theme.geometry.groupedViewSpacing

            let w = clearImage.size.width
            let h = clearImage.size.height
            self.clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: w + self.clearButtonRightSpacing, height: h))
            self.clearButton?.setImage(clearImage, for: .normal)
            self.clearButton?.isHidden = true
            self.clearButton?.addTarget(self, action: #selector(self.clearButtonDidTouchUpInside(_:)), for: .touchUpInside)

            self.rightViewMode = .whileEditing
            self.rightView = self.clearButton

            self.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
            self.addTarget(self, action: #selector(self.textFieldDidEnd(_:)), for: .editingDidEnd)
            self.addTarget(self, action: #selector(self.textFieldDidBegin(_:)), for: .editingDidBegin)
        }

        self.applyUnfocusedStyle()
    }

    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        if self.enableCursorMotion {
            return super.closestPosition(to: point)
        }
        let beginning = self.beginningOfDocument
        let end = self.position(from: beginning, offset: self.text?.count ?? 0)
        return end
    }

    override var text: String? {
        didSet {
            self.clearButton?.isHidden = self.text?.isEmpty ?? true
        }
    }

    @objc func textFieldDidChange(_: TextField) {
        self.clearButton?.isHidden = self.text?.isEmpty ?? true
    }

    @objc func textFieldDidEnd(_: TextField) {
        self.clearButton?.isHidden = true
    }

    @objc func textFieldDidBegin(_: TextField) {
        self.clearButton?.isHidden = self.text?.isEmpty ?? true
    }

    @objc func clearButtonDidTouchUpInside(_: UIButton) {
        self.text = ""
        self.clearButton?.isHidden = true
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.origin.x + self.contentInset.left,
            y: bounds.origin.y,
            width: bounds.size.width - (self.contentInset.right + self.contentInset.left + self.clearButtonRightSpacing),
            height: bounds.size.height
        )
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return self.textRect(forBounds: bounds)
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height += self.contentInset.top + self.contentInset.bottom
        return size
    }

    /**
     Apply styles for a text field, which is going to become the first responder,
     i.e. get the input focus.
     */
    private func applyFocusedStyle() {
        guard let theme = self.theme else { return }
        self.layer.borderColor = theme.colors.textInputBorderActive.cgColor
        self.backgroundColor = self.normalBackgroundColor
    }

    /**
     Apply styles for a text field, which is going to stop being the first responder,
     i.e. lose the input focus, but still let user's input.
     */
    func applyUnfocusedStyle() {
        self.layer.borderColor = self.normalBorderColor
        self.backgroundColor = self.normalBackgroundColor
    }

    /**
     Apply styles for a text field, which is going to stop letting any input.
     */
    private func applyDisabledStyle() {
        guard let theme = self.theme else { return }
        self.layer.borderColor = self.normalBorderColor
        self.backgroundColor = theme.colors.textInputBackgroundDisabled
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            self.applyFocusedStyle()
        }
        return result
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        // textFieldDidEndEditing is called during the course of super.resignFirstResponder
        // apply the style early so that textFieldDidEndEditing is able to change it
        self.applyUnfocusedStyle()
        let result = super.resignFirstResponder()
        if !result {
            self.applyFocusedStyle()
        }
        return result
    }

    public override var isEnabled: Bool {
        get { return super.isEnabled }
        set {
            if newValue {
                self.applyUnfocusedStyle()
            } else {
                self.applyDisabledStyle()
            }
            super.isEnabled = newValue
        }
    }
}
