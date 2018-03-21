//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
  Can be used to customize the UI
 */
public struct IdentityUITheme {

    /// Default UI theme object
    public static let `default` = IdentityUITheme()

    /// The logo that's displayed on the identifier screen
    public var titleLogo: UIImage?

    ///
    public struct Geometry {
        /// Default curved corner radius of controls
        public var cornerRadius: CGFloat = 4
        /// Default spacing between views that form a grouping
        public var groupedViewSpacing: CGFloat = 8
    }

    ///
    public struct Colors {
        ///
        public var iconTint = UIColor.schibstedDarkGray
        ///
        public var checkedBox = UIColor.schibstedPrimary
        ///
        public var uncheckedBox = UIColor.schibstedBlack
        ///
        public var normalText = UIColor.schibstedBlack
        ///
        public var errorText = UIColor.schibstedError
        ///
        public var infoText = UIColor.schibstedDarkGray
        ///
        public var primaryButton = UIColor.schibstedPrimary
        ///
        public var primaryButtonPressed = UIColor.schibstedPrimaryActive
        ///
        public var primaryButtonDisabled = UIColor.schibstedPrimaryDisabled
        ///
        public var primaryButtonText = UIColor.schibstedWhite
        ///
        public var secondaryButton = UIColor.schibstedSecondary
        ///
        public var secondaryButtonPressed = UIColor.schibstedSecondaryActive
        ///
        public var secondaryButtonDisabled = UIColor.schibstedSecondaryDisabled
        ///
        public var secondaryButtonText = UIColor.schibstedWhite
        ///
        public var errorBorder = UIColor.schibstedError
        ///
        public var textInputBorder = UIColor.schibstedMediumGray
        ///
        public var textInputBorderActive = UIColor.schibstedPrimary
        ///
        public var textInputBackground = UIColor.schibstedWhite
        ///
        public var textInputBackgroundDisabled = UIColor.schibstedVeryLightGray
        ///
        public var textInputCursor = UIColor.schibstedPrimary
    }

    ///
    public struct Icons {
        ///
        public var chevronLeft = UIImage.schibstedChevronLeft
        ///
        public var clearTextInput = UIImage.schibstedClearInput
        ///
        public var cancelNavigation = UIImage.schibstedCross
        ///
        public var navigateBack = UIImage.schibstedBackArrow
        ///
        public var checkedBox = UIImage.schibstedCheckedBox
        ///
        public var uncheckedBox = UIImage.schibstedUncheckedBox
    }

    ///
    public struct Fonts {
        ///
        public var heading = Style.fonts.h1.font
        ///
        public var title = Style.fonts.h2.font
        ///
        public var normal = Style.fonts.body.font
        ///
        public var error = Style.fonts.small.font
        ///
        public var info = Style.fonts.small.font
    }

    ///
    public struct TextAttributes {
        ///
        public var smallParagraph = Style.fonts.small.attributed()
        ///
        public var centeredNormalParagraph = Style.fonts.body.attributed(alignment: .center)
        ///
        public var linkButton = {
            Style.fonts.small.attributed().mergedByOverwriting(with: [
                .foregroundColor: UIColor.schibstedPrimary,
                .underlineColor: UIColor.schibstedPrimary,
                .underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
            ])
        }()
        ///
        public var textButton = {
            Style.fonts.body.attributed().mergedByOverwriting(with: [
                .foregroundColor: UIColor.schibstedPrimary,
                .underlineColor: UIColor.schibstedPrimary,
            ])
        }()
    }

    ///
    public var geometry = Geometry()
    ///
    public var colors = Colors()
    ///
    public var icons = Icons()
    ///
    public var fonts = Fonts()
    ///
    public var textAttributes = TextAttributes()
}
