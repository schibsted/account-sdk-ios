//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

struct AtomicInt {
    private var queue = DispatchQueue(label: "com.schibsted.identity.AtomicInt")
    private var _value = 0
    init(_ value: Int = 0) {
        _value = value
    }
    var value: Int {
        get {
            var value: Int = 0
            queue.sync {
                value = self._value
            }
            return value
        }

        set {
            queue.sync {
                self._value = newValue
            }
        }
    }

    @discardableResult
    mutating func getAndIncrement() -> Int {
        var previousValue = 0
        queue.sync {
            previousValue = self._value
            self._value += 1
        }
        return previousValue
    }

    @discardableResult
    mutating func getAndDecrement() -> Int {
        var previousValue = 0
        queue.sync {
            previousValue = self._value
            self._value -= 1
        }
        return previousValue
    }
}
