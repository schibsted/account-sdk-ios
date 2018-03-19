//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class WeakValue<V: AnyObject>: CustomStringConvertible {
    weak var value: V?
    init(_ value: V?) {
        self.value = value
    }
    var description: String {
        return "WeakValue<\(V.self)>(\(String(describing: self.value)))"
    }
}

class SynchronizedWeakDictionary<K: Hashable, V: AnyObject> {
    private let dictionary = SynchronizedDictionary<K, WeakValue<V>>()
    subscript(key: K) -> V? {
        set {
            guard newValue != nil else {
                self.dictionary[key] = nil
                return
            }
            self.dictionary[key] = WeakValue(newValue)
        }
        get {
            guard let weakValue = self.dictionary.removeValue(forKey: key, onlyIf: { $0.value == nil }) else {
                return nil
            }
            return weakValue.value
        }
    }

    var count: Int {
        return self.dictionary.count
    }

    func removeAll(keepingCapacity keepCapacity: Bool = false) {
        self.dictionary.removeAll(keepingCapacity: keepCapacity)
    }
}
