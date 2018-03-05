//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/// This is for the Result success type if no value is expected
public typealias NoValue = ()

/**
 A result object is generally used for asynchronous callbacks in the SDK
 */
public enum Result<T, E: Error> {

    /// Denotes a successful journey of bits and instructions through the virtual world.
    /// Contains the value that was meant to be received in a success case.
    case success(T)

    /// Something went wrong. Contains the `Error` object with more information.
    case failure(E)

    func materialize() throws -> T {
        switch self {
        case let .success(value): return value
        case let .failure(error): throw error
        }
    }
}

extension Result: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success: return "Success!"
        case let .failure(error): return "Failure: \(error)"
        }
    }
}

extension Result: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .success(value): return "Success: \(value)"
        case let .failure(error): return "Failure: \(error)"
        }
    }
}
