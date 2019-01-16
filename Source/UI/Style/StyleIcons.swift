//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

///
public enum StyleIconKind: String {
    ///
    case backArrow = "back-arrow"
    ///
    case checkedBox = "checked-box"
    ///
    case uncheckedBox = "unchecked-box"
    ///
    case cross
    ///
    case chevronLeft = "chevron-left"
    ///
    case clearInput = "clear-input"
    ///
    case rememberMeInfo = "remember-me-info"
    ///
    case infoPlaceholder = "placeholder"
    ///
    case circularInfo = "circular-info"
}

extension UIImage {
    convenience init?(icon: StyleIconKind) {
        let bundle = Bundle(for: IdentityManager.self)
        self.init(named: icon.rawValue, in: bundle, compatibleWith: nil)
    }
}

/**
 This represents the current values of the icons. Use the `Style` object to
 get them. This object intentionally has no public initializer
 */
public struct StyleIcons {
    // Don't allow clients to create this
    init() {}

    /**
     Get icons

     - parameter kind: which icon you want to get
     */
    public subscript(kind: StyleIconKind) -> UIImage {
        guard let image = UIImage(icon: kind) else {
            preconditionFailure("Icon '\(kind)' not found")
        }
        return image
    }
}
