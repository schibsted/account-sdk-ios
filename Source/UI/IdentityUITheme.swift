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

    /// Controls spacings and curvatures of views
    public struct Geometry {
        /// Spacing between views that form a grouping
        public var groupedViewSpacing: CGFloat = 8
        /// Spacing for in between titles and their associated input fields
        public var titleViewSpacing: CGFloat = 4

        /// Corner radius of buttons and popups
        public var cornerRadius: CGFloat = 4
        /// Corner radius of input fields
        public var inputViewCornerRadius: CGFloat = 4
        /// Corner radius for views encapsulating other views
        public var contentGroupingCornerRadius: CGFloat = 12
    }

    ///
    public struct Colors {
        ///
        public var iconTint = UIColor.schibstedDarkGray
        ///
        public var barTintColor = UIColor.schibstedVeryLightGray
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
        public var secondaryButtonText = UIColor.schibstedPrimary
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
        /// Left chevron icon used to navigating input fields
        public var chevronLeft = UIImage.schibstedChevronLeft
        /// Text field clear text icon. Set to nil for default iOS icon
        public var clearTextInput: UIImage? = .schibstedClearInput
        /// Top right X button to exit the login flow
        public var cancelNavigation = UIImage.schibstedCross
        /// Top left back button to go to previous screen
        public var navigateBack = UIImage.schibstedBackArrow
        /// Checkbox checked image
        public var checkedBox = UIImage.schibstedCheckedBox
        /// Checkbox unchecked image
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
        public var infoParagraph = Style.fonts.body.attributed(alignment: .center).mergedByOverwriting(with: [
            .foregroundColor: UIColor.schibstedDarkGray,
        ])
        ///
        public var linkButton = {
            Style.fonts.small.attributed().mergedByOverwriting(with: [
                .foregroundColor: UIColor.schibstedPrimary,
                .underlineColor: UIColor.schibstedPrimary,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
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
