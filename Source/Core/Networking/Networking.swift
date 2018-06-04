//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

typealias URLSessionTaskCallback = (Data?, URLResponse?, Error?) -> Void

//
// printing NSURLSessionTaskState enum actually just prings
// "NSURLSessionTaskState". So this fixes that :/
//
extension URLSessionTask.State: CustomStringConvertible {
    public var description: String {
        let prefix = "NSURLSessionTaskState."
        switch self {
        case .canceling:
            return prefix + "canceling"
        case .completed:
            return prefix + "completed"
        case .running:
            return prefix + "running"
        case .suspended:
            return prefix + "suspended"
        }
    }
}

struct Networking {
    static var proxy: NetworkingProxy = DefaultNetworkingProxy()

    static var additionalHeaders: [String: String]? {
        get {
            return self.proxy.additionalHeaders
        }
        set(newValue) {
            self.proxy.additionalHeaders = newValue
        }
    }

    static func dataTask(
        for session: URLSession,
        request: URLRequest,
        completion: URLSessionTaskCallback? = nil
    ) -> URLSessionDataTask {
        return self.proxy.dataTask(for: session, request: request, completion: completion)
    }

    static func send(
        to url: URL,
        using httpMethod: HTTPMethod,
        headers: [Networking.Header: String]? = nil,
        formData: [String: String]? = nil,
        completion: URLSessionTaskCallback? = nil
    ) -> URLSessionDataTask {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue

        if let formData = formData, let data = try? Networking.Utils.encodeFormData(formData), data.count > 0 {
            request.httpBody = data
            request.setValue("\(data.count)", for: .contentLength)
            request.setValue("application/x-www-form-urlencoded", for: .contentType)
        }

        for (key, value) in self.proxy.additionalHeaders ?? [:] {
            request.setValue(value, forHTTPHeaderField: key)
        }

        for (key, value) in headers ?? [:] {
            request.setValue(value, for: key)
        }

        log(level: .debug, "\n  \(request.cURLRepresentation)", tag: "CURL")
        return self.dataTask(for: self.proxy.session, request: request, completion: completion)
    }
}
