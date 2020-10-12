//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//
import UIKit

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
        font = theme.fonts.normal
        layer.borderWidth = 1
        layer.cornerRadius = theme.geometry.inputViewCornerRadius
        textColor = theme.colors.normalText
        // cursor color
        tintColor = theme.colors.textInputCursor
        contentInset = UIEdgeInsets(
            top: theme.geometry.groupedViewSpacing,
            left: 16,
            bottom: theme.geometry.groupedViewSpacing,
            right: 16
        )

        if clearButtonMode == .whileEditing, let clearImage = theme.icons.clearTextInput {
            //
            // Just setting the rightViewMode to .whileEditing seems to not work. The view shows up as soon
            // as the textfield becomes first responder. So we handle the state ourself
            //
            clearButtonMode = .never

            clearButtonRightSpacing = theme.geometry.groupedViewSpacing

            let w = clearImage.size.width
            let h = clearImage.size.height
            clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: w + clearButtonRightSpacing, height: h))
            clearButton?.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: theme.geometry.groupedViewSpacing)
            clearButton?.setImage(clearImage, for: .normal)
            clearButton?.isHidden = true
            clearButton?.addTarget(self, action: #selector(clearButtonDidTouchUpInside(_:)), for: .touchUpInside)

            rightViewMode = .whileEditing
            rightView = clearButton

            addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            addTarget(self, action: #selector(textFieldDidEnd(_:)), for: .editingDidEnd)
            addTarget(self, action: #selector(textFieldDidBegin(_:)), for: .editingDidBegin)
        }

        applyUnfocusedStyle()
    }

    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        if enableCursorMotion {
            return super.closestPosition(to: point)
        }
        let beginning = beginningOfDocument
        let end = position(from: beginning, offset: text?.count ?? 0)
        return end
    }

    override var text: String? {
        didSet {
            clearButton?.isHidden = text?.isEmpty ?? true
        }
    }

    @objc func textFieldDidChange(_: TextField) {
        clearButton?.isHidden = text?.isEmpty ?? true
    }

    @objc func textFieldDidEnd(_: TextField) {
        clearButton?.isHidden = true
    }

    @objc func textFieldDidBegin(_: TextField) {
        clearButton?.isHidden = text?.isEmpty ?? true
    }

    @objc func clearButtonDidTouchUpInside(_: UIButton) {
        text = ""
        clearButton?.isHidden = true
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.origin.x + contentInset.left,
            y: bounds.origin.y,
            width: bounds.size.width - (contentInset.right + contentInset.left + clearButtonRightSpacing),
            height: bounds.size.height
        )
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height += contentInset.top + contentInset.bottom
        return size
    }

    /**
     Apply styles for a text field, which is going to become the first responder,
     i.e. get the input focus.
     */
    private func applyFocusedStyle() {
        guard let theme = self.theme else { return }
        layer.borderColor = theme.colors.textInputBorderActive.cgColor
        backgroundColor = normalBackgroundColor
    }

    /**
     Apply styles for a text field, which is going to stop being the first responder,
     i.e. lose the input focus, but still let user's input.
     */
    func applyUnfocusedStyle() {
        layer.borderColor = normalBorderColor
        backgroundColor = normalBackgroundColor
    }

    /**
     Apply styles for a text field, which is going to stop letting any input.
     */
    private func applyDisabledStyle() {
        guard let theme = self.theme else { return }
        layer.borderColor = normalBorderColor
        backgroundColor = theme.colors.textInputBackgroundDisabled
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            applyFocusedStyle()
        }
        return result
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        // textFieldDidEndEditing is called during the course of super.resignFirstResponder
        // apply the style early so that textFieldDidEndEditing is able to change it
        applyUnfocusedStyle()
        let result = super.resignFirstResponder()
        if !result {
            applyFocusedStyle()
        }
        return result
    }

    public override var isEnabled: Bool {
        get { return super.isEnabled }
        set {
            if newValue {
                applyUnfocusedStyle()
            } else {
                applyDisabledStyle()
            }
            super.isEnabled = newValue
        }
    }
}
