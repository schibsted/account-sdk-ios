//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
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
}

extension NetworkingProxy {
    func dataTask(
        for session: URLSession,
        request: URLRequest
    ) -> URLSessionDataTask {
        return self.dataTask(for: session, request: request, completion: nil)
    }
}
