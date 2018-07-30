//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class SynchronizedDictionary<K: Hashable, V> {
    private var dictionary: [K: V] = [:]
    private let dispatchQueue = DispatchQueue(label: "com.schibsted.identity.SynchronizedDictionary", attributes: .concurrent)

    subscript(key: K) -> V? {
        set {
            self.dispatchQueue.async(flags: .barrier) {
                self.dictionary[key] = newValue
            }
        }
        get {
            var value: V?
            self.dispatchQueue.sync {
                value = self.dictionary[key]
            }
            return value
        }
    }

    /*
     This provides a way to transactionally do a pattern such as:
     if let value = dictionary[key] {
       // check some conditions related to value
       dictionary.removeValue(forKey: key)
     }

     e.g.

     let value = dictionary.removeValue(
       forKey: key,
       onlyIf { // check some conditions related to $0 }
     )
     */
    func removeValue(forKey key: K, onlyIf predicate: (V) -> Bool) -> V? {
        var maybeValue: V?
        self.dispatchQueue.sync {
            guard let value = self.dictionary[key] else {
                return
            }
            maybeValue = value
            if predicate(value) {
                self.dictionary[key] = nil
            }
        }
        return maybeValue
    }

    var count: Int {
        var count = 0
        self.dispatchQueue.sync {
            count = self.dictionary.count
        }
        return count
    }

    func removeAll(keepingCapacity keepCapacity: Bool = false) {
        self.dispatchQueue.async(flags: .barrier) {
            self.dictionary.removeAll(keepingCapacity: keepCapacity)
        }
    }

    func take() -> [K: V] {
        return self.dispatchQueue.sync {
            self.dictionary
        }
    }
}
