//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class WeakValue<V: AnyObject>: CustomStringConvertible {
    weak var value: V?
    init(_ value: V?) {
        self.value = value
    }
    var description: String {
        return "WeakValue<\(V.self)>(\(String(describing: value)))"
    }
}

class SynchronizedWeakDictionary<K: Hashable, V: AnyObject> {
    private let dictionary = SynchronizedDictionary<K, WeakValue<V>>()
    subscript(key: K) -> V? {
        set {
            guard newValue != nil else {
                dictionary[key] = nil
                return
            }
            dictionary[key] = WeakValue(newValue)
        }
        get {
            guard let weakValue = self.dictionary.removeValue(forKey: key, if: { $0.value == nil }) else {
                return nil
            }
            return weakValue.value
        }
    }

    var count: Int {
        return dictionary.count
    }

    func removeAll(keepingCapacity keepCapacity: Bool = false) {
        dictionary.removeAll(keepingCapacity: keepCapacity)
    }

    func forEach(_ callback: @escaping (K, WeakValue<V>) -> Void) {
        dictionary.forEach(callback)
    }
}
