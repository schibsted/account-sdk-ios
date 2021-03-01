//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import UIKit

class LogoStackView: UIStackView, Themeable {
    func applyTheme(theme: IdentityUITheme) {
        heightAnchor.constraint(equalToConstant: 20).isActive = true

        alignment = .center

        #if SWIFT_PACKAGE
            let bundle = Bundle.module
        #else
            let bundle = Bundle(for: IdentityUI.self)
        #endif

        let schImage = UIImage(named: "schibsted-logo", in: bundle, compatibleWith: nil)
        let schImageView = UIImageView(image: schImage)
        schImageView.contentMode = .scaleAspectFit
        schImageView.widthAnchor.constraint(equalToConstant: 69).isActive = true
        schImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        schImageView.translatesAutoresizingMaskIntoConstraints = false
        schImageView.tintColor = theme.colors.schibstedLogoTint

        let filler = UIView(frame: .zero)
        filler.translatesAutoresizingMaskIntoConstraints = false
        filler.setContentCompressionResistancePriority(.required, for: .horizontal)

        if let titleLogo = theme.titleLogo {
            let customLogoImageView = UIImageView(image: titleLogo)
            let scale = titleLogo.size.width / titleLogo.size.height
            customLogoImageView.contentMode = .scaleAspectFit
            customLogoImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
            customLogoImageView.widthAnchor.constraint(equalToConstant: ceil(20 * scale)).isActive = true
            customLogoImageView.translatesAutoresizingMaskIntoConstraints = false

            addArrangedSubview(customLogoImageView)
            addArrangedSubview(filler)
            addArrangedSubview(schImageView)
        } else {
            addArrangedSubview(schImageView)
            addArrangedSubview(filler)
        }
    }
}
