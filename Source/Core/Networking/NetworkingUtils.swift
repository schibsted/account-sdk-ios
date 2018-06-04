//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
extension Networking {
    struct Utils {
        static func ensureResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> ([Int]) throws -> Data {
            return { expectedStatuses in
                if let error = error {
                    throw NetworkingError.requestError(error)
                }
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkingError.httpObjectConversionError
                }
                guard let data = data else {
                    throw NetworkingError.noData(response.statusCode)
                }
                if expectedStatuses.count > 0 && !expectedStatuses.contains(response.statusCode) {
                    throw NetworkingError.unexpectedStatus(status: response.statusCode, data: data)
                }
                return data
            }
        }

        static func encodeFormData(_ formData: [String: String]) throws -> Data {
            var formDataComponents = URLComponents()
            formDataComponents.queryItems = formData.reduce([URLQueryItem]()) {
                $0 + [URLQueryItem(name: $1.key, value: $1.value)]
            }

            // "+" character, even though not encoded by `URLComponents`, needs to be encoded in www form.
            let allButPlus = CharacterSet(charactersIn: "+").inverted

            guard let formattedFormData = formDataComponents.percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: allButPlus) else {
                throw GenericError.Unexpected("Failed to encode \(formData)")
            }

            guard let data = formattedFormData.data(using: String.Encoding.utf8) else {
                throw NetworkingError.formDataEncodingError
            }
            return data
        }
    }
}
