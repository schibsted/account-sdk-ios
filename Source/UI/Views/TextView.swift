//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class TextView: UITextView, Themeable {
    override func updateConstraints() {
        self.heightAnchor.constraint(equalToConstant: self.sizeThatFits(self.bounds.size).height).isActive = true
        super.updateConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.textContainerInset = .zero
    }

    func applyTheme(theme: IdentityUITheme) {
        self.font = theme.fonts.normal
        self.textColor = theme.colors.normalText
    }
}
