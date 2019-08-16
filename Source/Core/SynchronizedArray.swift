//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class SynchronizedArray<Element>: ExpressibleByArrayLiteral {
    private let array: Atomic<[Element]>

    required init(arrayLiteral elements: Element...) {
        self.array = Atomic(elements)
    }

    required init(elements: [Element]) {
        self.array = Atomic(elements)
    }

    init() {
        self.array = Atomic([])
    }

    var data: [Element] {
        get {
            return self.array.value
        }
        set {
            self.array.value = newValue
        }
    }

    subscript(index: Int) -> Element {
        get {
            return self.array.value[index]
        }
        set {
            self.array.getAnd(set: { $0[index] = newValue })
        }
    }

    var count: Int {
        return self.array.value.count
    }

    func append(_ element: Element) {
        self.array.getAnd(set: { $0.append(element) })
    }
}
