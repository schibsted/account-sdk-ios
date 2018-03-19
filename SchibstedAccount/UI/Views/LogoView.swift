//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class LogoStackView: UIStackView, Themeable {
    func applyTheme(theme _: IdentityUITheme) {
        self.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let image = UIImage(named: "schibsted-logo", in: Bundle(for: IdentityUI.self), compatibleWith: nil)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: 69).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 11).isActive = true

        let filler = UIView(frame: self.frame)
        filler.translatesAutoresizingMaskIntoConstraints = false
        filler.widthAnchor.constraint(equalToConstant: self.frame.width).isActive = true

        self.addArrangedSubview(imageView)
        self.addArrangedSubview(filler)
    }
}
