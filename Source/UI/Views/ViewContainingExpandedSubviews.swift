//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class ViewContainingExtendedSubviews: UIView {
    var extendedSubviews: [UIView] = []
    var minExtendedSideLength: CGFloat = 44

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for extendedSubview in extendedSubviews {
            let pointForExtendedSubview = extendedSubview.convert(point, from: self)
            let dx = -ceil(max(0, minExtendedSideLength - extendedSubview.bounds.width) / 2.0)
            let dy = -ceil(max(0, minExtendedSideLength - extendedSubview.bounds.height) / 2.0)
            let extendedSubviewBounds = extendedSubview.bounds.insetBy(dx: dx, dy: dy)

            if extendedSubviewBounds.contains(pointForExtendedSubview) {
                return extendedSubview
            }
        }
        return super.hitTest(point, with: event)
    }
}
