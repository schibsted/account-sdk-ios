//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class TextView: UITextView, Themeable {
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
    }

    func applyTheme(theme: IdentityUITheme) {
        font = theme.fonts.normal
        textColor = theme.colors.normalText
    }
}
