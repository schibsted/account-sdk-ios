//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class AtomicInt {
    private let _value: Atomic<Int>
    init(_ value: Int = 0) {
        self._value = Atomic<Int>(value)
    }
    var value: Int {
        get {
            return self._value.value
        }

        set {
            self._value.value = newValue
        }
    }

    @discardableResult
    func getAndIncrement() -> Int {
        return self._value.getAnd(set: { $0 += 1 })
    }

    @discardableResult
    func getAndDecrement() -> Int {
        return self._value.getAnd(set: { $0 -= 1 })
    }
}
