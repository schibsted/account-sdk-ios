//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class PrimaryButton: UIButton, Themeable {
    var isAnimating = false {
        didSet {
            guard oldValue != isAnimating else {
                return
            }
            if isAnimating {
                startAnimating()
            } else {
                stopAnimating()
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
        titleLabel?.font = theme.fonts.normal
        adjustsImageWhenHighlighted = false
        setBackgroundImage(normalColor.convertImage(), for: .normal)
        setTitleColor(textColor, for: .normal)
        setBackgroundImage(disabledColor.convertImage(), for: .disabled)
        setTitleColor(textColor, for: .disabled)
        setBackgroundImage(pressedColor.convertImage(), for: .highlighted)
        setTitleColor(textColor, for: .highlighted)
        backgroundColor = UIColor.clear
        contentEdgeInsets = UIEdgeInsets(
            top: theme.geometry.groupedViewSpacing,
            left: theme.geometry.groupedViewSpacing,
            bottom: theme.geometry.groupedViewSpacing,
            right: theme.geometry.groupedViewSpacing
        )
        layer.cornerRadius = theme.geometry.cornerRadius
        layer.masksToBounds = true

        heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    func applyTheme(theme: IdentityUITheme) {
        applyTheme(
            normalColor: theme.colors.primaryButton,
            pressedColor: theme.colors.primaryButtonPressed,
            disabledColor: theme.colors.primaryButtonDisabled,
            textColor: theme.colors.primaryButtonText,
            theme: theme
        )
    }

    private func startAnimating() {
        isEnabled = false
        let indicator = UIActivityIndicatorView()
        addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        indicator.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true

        indicator.startAnimating()
    }

    private func stopAnimating() {
        isEnabled = true
        titleLabel?.isHidden = false
        for view in subviews {
            if let indicator = view as? UIActivityIndicatorView {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }
}
