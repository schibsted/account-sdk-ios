//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

protocol NetworkingProxy {
    var session: URLSession { get }
    func dataTask(
        for session: URLSession,
        request: URLRequest,
        completion: URLSessionTaskCallback?
    ) -> URLSessionDataTask
    var additionalHeaders: [String: String]? { get set }
}

extension NetworkingProxy {
    func dataTask(
        for session: URLSession,
        request: URLRequest
    ) -> URLSessionDataTask {
        return dataTask(for: session, request: request, completion: nil)
    }
}
