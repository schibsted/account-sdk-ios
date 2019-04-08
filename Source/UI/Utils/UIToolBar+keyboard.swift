//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

extension UIToolbar {
    static func forKeyboard(
        target: Any?,
        doneString: String? = nil,
        doneSelector: Selector? = nil,
        previousSelector: Selector? = nil,
        nextSelector: Selector? = nil,
        leftChevronImage: UIImage? = nil
    ) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        var done: UIBarButtonItem?
        if let doneSelector = doneSelector {
            done = UIBarButtonItem(title: doneString, style: .done, target: target, action: doneSelector)
        }

        var previous: UIBarButtonItem?
        if let previousSelector = previousSelector, let leftChevronImage = leftChevronImage {
            previous = UIBarButtonItem(image: leftChevronImage, style: .plain, target: target, action: previousSelector)
        }

        var next: UIBarButtonItem?
        if let nextSelector = nextSelector, let leftChevronImage = leftChevronImage, let cgImage = leftChevronImage.cgImage {
            let chevronRight = UIImage(cgImage: cgImage, scale: leftChevronImage.scale, orientation: .upMirrored)
            next = UIBarButtonItem(image: chevronRight, style: .plain, target: target, action: nextSelector)
        }

        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([previous, next, flex, done].compactOrFlatMap { $0 }, animated: true)
        return toolbar
    }
}
