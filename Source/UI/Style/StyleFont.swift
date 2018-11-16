//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Different fonts and their associated properties that are part of the schibsted style
 */
public enum StyleFont {
    ///
    case h0
    ///
    case h1
    ///
    case h2
    ///
    case bodyBold
    ///
    case body
    ///
    case bodyAlt
    ///
    case bodyColor
    ///
    case bodyWhite
    ///
    case small
    ///
    case smallColor
    ///
    case tiny

    private var size: CGFloat {
        switch self {
        case .h0: return 50
        case .h1: return 28
        case .h2: return 20
        case .bodyBold, .body, .bodyAlt, .bodyColor, .bodyWhite:
            return 16
        case .small, .smallColor:
            return 14
        case .tiny: return 12
        }
    }

    private var lineHeight: CGFloat {
        switch self {
        case .h0: return 58
        case .h1: return 36
        case .h2: return 28
        case .bodyBold, .body, .bodyAlt, .bodyColor, .bodyWhite:
            return 24
        case .small, .smallColor:
            return 16
        case .tiny: return 16
        }
    }

    private var weight: CGFloat {
        switch self {
        case .h0, .h1: return UIFont.Weight.heavy.rawValue
        case .h2, .bodyBold: return UIFont.Weight.medium.rawValue
        case .body, .bodyAlt, .bodyColor, .bodyWhite, .small, .smallColor, .tiny:
            return UIFont.Weight.regular.rawValue
        }
    }

    /// Returns the UIFont object associated with the style
    public var font: UIFont {
        return UIFont.systemFont(ofSize: self.size, weight: UIFont.Weight(rawValue: self.weight))
    }

    private var color: UIColor {
        switch self {
        case .bodyAlt, .small, .tiny:
            return Style.colors[.darkGray]
        case .bodyColor, .smallColor:
            return Style.colors[.primary]
        case .bodyWhite: return Style.colors[.white]
        case .h0, .h1, .h2, .bodyBold, .body:
            return Style.colors[.black]
        }
    }

    /**
     Retrieves attributes for NSAttributedString with requested configuration
     */

    public func attributed(color: UIColor? = nil, alignment: NSTextAlignment? = nil) -> [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = self.lineHeight
        style.lineBreakMode = .byWordWrapping
        style.alignment = alignment ?? .left
        return [
            .paragraphStyle: style,
            .font: self.font,
            .foregroundColor: color ?? self.color,
        ]
    }
}
