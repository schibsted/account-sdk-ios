//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class LogoStackView: UIStackView, Themeable {
    func applyTheme(theme: IdentityUITheme) {
        self.heightAnchor.constraint(equalToConstant: 20).isActive = true

        self.alignment = .center

        let schImage = UIImage(named: "schibsted-logo", in: Bundle(for: IdentityUI.self), compatibleWith: nil)
        let schImageView = UIImageView(image: schImage)
        schImageView.contentMode = .scaleAspectFit
        schImageView.widthAnchor.constraint(equalToConstant: 69).isActive = true
        schImageView.heightAnchor.constraint(equalToConstant: 11).isActive = true

        let filler = UIView(frame: self.frame)
        filler.translatesAutoresizingMaskIntoConstraints = false
        filler.widthAnchor.constraint(equalToConstant: self.frame.width).isActive = true

        if let titleLogo = theme.titleLogo {
            let customLogoImageView = UIImageView(image: titleLogo)
            let scale = titleLogo.size.width / titleLogo.size.height
            customLogoImageView.contentMode = .scaleAspectFit
            customLogoImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
            customLogoImageView.widthAnchor.constraint(equalToConstant: 20 * scale).isActive = true

            self.addArrangedSubview(customLogoImageView)
            self.addArrangedSubview(filler)
            self.addArrangedSubview(schImageView)
        } else {
            self.addArrangedSubview(schImageView)
            self.addArrangedSubview(filler)
        }
    }
}
