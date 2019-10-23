//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class LogoStackView: UIStackView, Themeable {
    func applyTheme(theme: IdentityUITheme) {
        heightAnchor.constraint(equalToConstant: 20).isActive = true

        alignment = .center

        let schImage = UIImage(named: "schibsted-logo", in: Bundle(for: IdentityUI.self), compatibleWith: nil)
        let schImageView = UIImageView(image: schImage)
        schImageView.contentMode = .scaleAspectFit
        schImageView.widthAnchor.constraint(equalToConstant: 69).isActive = true
        schImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        schImageView.translatesAutoresizingMaskIntoConstraints = false

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
