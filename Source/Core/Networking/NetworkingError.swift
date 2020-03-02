//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

enum NetworkingError: Error {
    case requestError(Error)
    case unexpectedStatus(status: Int, data: Data)
    case formDataEncodingError
    case httpObjectConversionError
    case malformedURL
    case noData(Int)
    case unexpected(Error)

    init(_ error: Error) {
        if let error = error as? NetworkingError {
            self = error
        } else {
            self = .unexpected(error)
        }
    }
}

extension NetworkingError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .requestError(error):
            return "Error response from server: \(error)"
        case let .unexpectedStatus(status, data):
            let string = String(data: data, encoding: .utf8)
            return "Unexpected status code from server: got \(status) (\(string as Optional))"
        case .formDataEncodingError:
            return "Could not encode form data"
        case .httpObjectConversionError:
            return "Response object invalid type"
        case let .noData(status):
            return "Expected data - got status code \(status)"
        case let .unexpected(error):
            return "Unexpected error: \(error)"
        case .malformedURL:
            return "The URL is malformed"
        }
    }
}
