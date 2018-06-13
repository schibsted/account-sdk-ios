//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class PrimaryButton: UIButton, Themeable {
    var isAnimating = false {
        didSet {
            guard oldValue != self.isAnimating else {
                return
            }
            if self.isAnimating {
                self.startAnimating()
            } else {
                self.stopAnimating()
            }
        }
    }

    func applyTheme(
        normalColor: UIColor,
        pressedColor: UIColor,
        disabledColor: UIColor,
        textColor: UIColor,
        theme: IdentityUITheme
    ) {
        self.titleLabel?.font = theme.fonts.normal
        self.adjustsImageWhenHighlighted = false
        self.setBackgroundImage(normalColor.convertImage(), for: .normal)
        self.setTitleColor(textColor, for: .normal)
        self.setBackgroundImage(disabledColor.convertImage(), for: .disabled)
        self.setTitleColor(textColor, for: .disabled)
        self.setBackgroundImage(pressedColor.convertImage(), for: .highlighted)
        self.setTitleColor(textColor, for: .highlighted)
        self.backgroundColor = UIColor.clear
        self.contentEdgeInsets = UIEdgeInsets(
            top: theme.geometry.groupedViewSpacing,
            left: theme.geometry.groupedViewSpacing,
            bottom: theme.geometry.groupedViewSpacing,
            right: theme.geometry.groupedViewSpacing
        )
        self.layer.cornerRadius = theme.geometry.cornerRadius
        self.layer.masksToBounds = true

        self.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    func applyTheme(theme: IdentityUITheme) {
        self.applyTheme(
            normalColor: theme.colors.primaryButton,
            pressedColor: theme.colors.primaryButtonPressed,
            disabledColor: theme.colors.primaryButtonDisabled,
            textColor: theme.colors.primaryButtonText,
            theme: theme
        )
    }

    private func startAnimating() {
        self.isEnabled = false
        let indicator = UIActivityIndicatorView()
        self.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        indicator.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16).isActive = true

        indicator.startAnimating()
    }

    private func stopAnimating() {
        self.isEnabled = true
        self.titleLabel?.isHidden = false
        for view in self.subviews {
            if let indicator = view as? UIActivityIndicatorView {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }
}
