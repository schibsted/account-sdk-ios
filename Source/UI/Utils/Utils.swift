//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension UIColor {
    func convertImage() -> UIImage {
        let rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        guard let context: CGContext = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }

        context.setFillColor(cgColor)
        context.fill(rect)

        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    func hexString() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let rgb: Int = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255) << 0
            return String(format: "#%06x", rgb)
        }

        return "#000000"
    }
}

extension UIViewController {
    func shakeAnimation(_ constraint: NSLayoutConstraint) {
        // FIXME: Oh God, there must be a better way...
        func generateAnimation(positions: [CGFloat]) {
            if positions.count == 0 {
                return
            }

            UIView.animate(withDuration: 0.1, delay: 0, options: [], animations: { [weak self] in
                constraint.constant = positions[0]
                self?.view.layoutIfNeeded()
            }, completion: { _ in
                var newPositions = positions
                newPositions.remove(at: 0)
                generateAnimation(positions: newPositions)
            })
        }

        generateAnimation(positions: [7, -5, 3, -1, 0])
    }
}

extension String {
    func localized(from bundle: Bundle) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "\(self) localization not found", comment: "")
    }

    func localized(from bundle: Bundle, _ vars: CVarArg...) -> String {
        let localizedString = localized(from: bundle)
        return String(format: localizedString, arguments: vars)
    }
}
