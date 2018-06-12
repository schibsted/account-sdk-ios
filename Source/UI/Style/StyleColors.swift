//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

private extension UIColor {
    convenience init(rgbaHex: String) {
        var normalizedString = rgbaHex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if normalizedString.hasPrefix("#") {
            normalizedString.remove(at: normalizedString.startIndex)
        }
        let rgbString = normalizedString.padding(toLength: 6, withPad: "0", startingAt: 0)
        let finalString = rgbString.count > 6
            ? rgbString.padding(toLength: 8, withPad: "0", startingAt: 6)
            : rgbString + "FF"

        var hexValue: UInt32 = 0
        Scanner(string: finalString).scanHexInt32(&hexValue)

        let divisor: CGFloat = 255
        self.init(
            red: CGFloat((hexValue & 0xFF00_0000) >> 24) / divisor,
            green: CGFloat((hexValue & 0x00FF_0000) >> 16) / divisor,
            blue: CGFloat((hexValue & 0x0000_FF00) >> 8) / divisor,
            alpha: CGFloat(hexValue & 0x0000_00FF) / divisor
        )
    }
}

///
public enum StyleColorKind: String {
    ///
    case primary
    ///
    case primaryActive
    ///
    case primaryDisabled
    ///
    case secondary
    ///
    case secondaryActive
    ///
    case secondaryDisabled

    ///
    case black
    ///
    case veryDarkGray
    ///
    case darkGray
    ///
    case mediumGray
    ///
    case lightGray
    ///
    case veryLightGray
    ///
    case white

    ///
    case validate
    ///
    case alert
    ///
    case error
}

/**
 This represents the current values of the colors. Use the `Style` object to
 get them. This object intentionally has no public initializer
 */
public struct StyleColors {
    private static var colors: [String: UIColor] = {
        let json = [
            "primary": "#1D72DB",
            "primaryActive": "#175BAF",
            "primaryDisabled": "#8EB8ED",
            "secondary": "#ffffff",
            "secondaryActive": "#F8F8F8",
            "secondaryDisabled": "#EAEAEA",

            "black": "#111111",
            "veryDarkGray": "#333333",
            "darkGray": "#666666",
            "mediumGray": "#B6B6B6",
            "lightGray": "#EAEAEA",
            "veryLightGray": "#F8F8F8",
            "white": "#FFFFFF",

            "validate": "#5D981C",
            "alert": "#C27B05",
            "error": "#D13649",
        ]

        var data: [String: UIColor] = [:]
        for (key, value) in json {
            // Catch inconsistencies between data and code representation
            assert(StyleColorKind(rawValue: key) != nil, "Color key '\(key)' not found in StyleColorKind")
            data[key] = UIColor(rgbaHex: value)
        }
        return data
    }()

    // Don't allow clients to create this
    init() {}

    /**
     Get colors

     - parameter kind: which color concept you want to get
     */
    public subscript(kind: StyleColorKind) -> UIColor {
        guard let color = type(of: self).colors[kind.rawValue] else {
            preconditionFailure("Color '\(kind)' not found")
        }
        return color
    }
}
