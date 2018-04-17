//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
@testable import SchibstedAccount

class CallData {
    var passedUrl: URL?
    var passedFormData: [String: String]?
    var passedHttpMethod: String?
    var passedRequest: URLRequest?
    var passedNSSession: Foundation.URLSession?
    var sentHTTPHeaders: [String: String]?
    var returnedResponse: URLResponse?
    var returnedData: Data?
    var returnedError: Error?
    init(passedUrl: URL? = nil,
         passedFormData: [String: String]? = nil,
         passedHttpMethod: String? = nil,
         passedRequest: URLRequest? = nil,
         passedNSSession: Foundation.URLSession? = nil,
         sentHTTPHeaders: [String: String]? = nil,
         returnedResponse: URLResponse? = nil,
         returnedData: Data? = nil,
         returnedError: Error? = nil) {
        self.passedUrl = passedUrl
        self.passedFormData = passedFormData
        self.passedHttpMethod = passedHttpMethod
        self.passedRequest = passedRequest
        self.passedNSSession = passedNSSession
        self.sentHTTPHeaders = sentHTTPHeaders
        self.returnedResponse = returnedResponse
        self.returnedData = returnedData
        self.returnedError = returnedError
    }
}

class TestingNetworkingProxy: NetworkingProxy {

    var session: URLSession {
        return self.internalProxy.session
    }

    var internalProxy: NetworkingProxy = StubbedNetworkingProxy()

    var calledOnce: Bool {
        return self.calls.count == 1
    }

    var callCount: Int {
        return self.calls.count
    }

    let dispatchQueue = DispatchQueue(label: "com.schibsted.identity.TestingNetworkHelper", attributes: [])
    var _calls: [CallData] = []
    var calls: [CallData] {
        return self.dispatchQueue.sync {
            self._calls
        }
    }

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

        let callData = CallData(
            passedUrl: request.url,
            passedFormData: extractFormData(),
            passedHttpMethod: request.httpMethod,
            passedRequest: request,
            passedNSSession: session
        )

        // When using operation queues and GCD this guy can potentially be bombarded from every direction. Protect it with all your might.
        self.dispatchQueue.async { [weak self] in
            self?._calls.append(callData)
        }

        let decoratedCallback: URLSessionTaskCallback? = completion != nil ? { data, response, error in
            callData.returnedData = data
            callData.returnedResponse = response
            callData.returnedError = error
            completion?(data, response, error)
        } : nil

        let dataTask = self.internalProxy.dataTask(for: session, request: request, completion: decoratedCallback)
        let requestHeaders = request.allHTTPHeaderFields ?? [:]
        let sessionHeaders = session.configuration.httpAdditionalHeaders as? [String: String] ?? [:]
        if let headers = session.configuration.httpAdditionalHeaders {
            precondition(
                headers is [String: String],
                "You've done something weird, HTTP headers should always be [String: String]"
            )
        }
        callData.sentHTTPHeaders = requestHeaders.merging(sessionHeaders) { current, _ in current }
        return dataTask
    }
}
