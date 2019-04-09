//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

extension Dictionary {
    func mergedByOverwriting(with other: [Key: Value]) -> [Key: Value] {
        var new = self
        for (k, v) in other {
            new[k] = v
        }
        return new
    }
}

extension Sequence {
    func compactOrFlatMap<ElementOfResult>(_ transform: (Self.Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        #if swift(>=4.1)
            return try self.compactMap(transform)
        #else
            return try self.flatMap(transform)
        #endif
    }
}

extension Collection where Iterator.Element == String {
    func trimmed() -> [String] {
        return self.map {
            $0.trimmingCharacters(in: CharacterSet.whitespaces)
        }.filter {
            $0.count > 0
        }
    }
}

extension NSLocking {
    func scope<T>(_ block: () -> T) -> T {
        self.lock()
        defer { self.unlock() }
        return block()
    }
}

protocol OptionalConvertible {
    associatedtype WrappedType
    var optional: WrappedType? { get }
}

extension Optional: OptionalConvertible {
    var optional: Wrapped? {
        return self
    }
}

extension Dictionary where Value: OptionalConvertible {
    func compactedValues() -> [Key: Value.WrappedType] {
        var destination: [Key: Value.WrappedType] = [:]
        for (key, value) in self {
            if let value = value.optional {
                destination[key] = value
            }
        }
        return destination
    }
}
