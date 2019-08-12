//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
@testable import SchibstedAccount

struct RequestData {
    var url: URL?
    var formData: [String: String]?
    var httpMethod: String?
    var request: URLRequest?
    var session: Foundation.URLSession?
    var headers: [String: String]?
}

struct ResponseData {
    var response: URLResponse?
    var data: Data?
    var error: Error?
}

class TestingNetworkingProxy: NetworkingProxy {

    var session: URLSession {
        return self.internalProxy.session
    }

    var additionalHeaders: [String : String]? {
        set(newValue) {
            self.internalProxy.additionalHeaders = newValue
        }
        get {
            return self.internalProxy.additionalHeaders
        }
    }

    var internalProxy: NetworkingProxy = StubbedNetworkingProxy()

    var requests = SynchronizedArray<RequestData>()
    var responses = SynchronizedArray<ResponseData>()

    func dataTask(
        for session: Foundation.URLSession,
        request: URLRequest,
        completion: URLSessionTaskCallback?
    ) -> URLSessionDataTask {

        func extractFormData() -> [String: String]? {
            guard request.allHTTPHeaderFields?["Content-Type"] == "application/x-www-form-urlencoded" else {
                return nil
            }
            guard let data = request.httpBody else {
                return nil
            }
            guard let string = String(data: data, encoding: .utf8) else {
                return nil
            }
            var formData: [String: String] = [:]
            for part in string.components(separatedBy: "&") {
                let kv = part.components(separatedBy: "=")
                guard kv.count == 2 else { continue }
                guard let key = kv[0].removingPercentEncoding, let value = kv[1].removingPercentEncoding else { continue }
                formData[key] = value
            }
            return formData
        }

        let requestHeaders = request.allHTTPHeaderFields ?? [:]
        let sessionHeaders = session.configuration.httpAdditionalHeaders as? [String: String] ?? [:]
        if let headers = session.configuration.httpAdditionalHeaders {
            precondition(
                headers is [String: String],
                "You've done something weird, HTTP headers should always be [String: String]"
            )
        }

        let requestData = RequestData(
            url: request.url,
            formData: extractFormData(),
            httpMethod: request.httpMethod,
            request: request,
            session: session,
            headers: requestHeaders.merging(sessionHeaders) { current, _ in current }
        )

        self.requests.append(requestData)

        let decoratedCallback: URLSessionTaskCallback? = completion != nil ? { [weak self] data, response, error in
            let responseData = ResponseData(response: response, data: data, error: error)
            self?.responses.append(responseData)
            completion?(data, response, error)
        } : nil

        return self.internalProxy.dataTask(for: session, request: request, completion: decoratedCallback)
    }
}
