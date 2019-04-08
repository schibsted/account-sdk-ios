//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class TextView: UITextView, Themeable {
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        self.textContainerInset = .zero
        self.textContainer.lineFragmentPadding = 0
    }

    func applyTheme(theme: IdentityUITheme) {
        self.font = theme.fonts.normal
        self.textColor = theme.colors.normalText
    }
}
