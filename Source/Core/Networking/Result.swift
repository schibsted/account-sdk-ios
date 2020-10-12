//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/// This is for the Result success type if no value is expected
public typealias NoValue = ()

public extension Result {
    func materialize() throws -> Success {
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
