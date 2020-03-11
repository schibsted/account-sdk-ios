//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class MockURLSessionDataTask: URLSessionDataTask {
    // This is the callback for when task.resume is called
    private var callback: URLSessionTaskCallback?

    // The next three are the arguments to the completion block of the URLSessionTask
    private let _data: Data?
    private var _response: HTTPURLResponse?
    private var _error: Error?

    private let _session: URLSession?
    private var _request: URLRequest

    private func handleCacheControl() {
        //
        // Here we parse the cache control header and make sure we do the right thing on the session.urlCache
        // This must be called before sending a response back to the caller, i.e. before the callback is invoked
        //
        guard let response = _response, let cacheControl = _response?.allHeaderFields["Cache-Control"] as? String else {
            return
        }
        let parts = cacheControl.split(separator: ",")
        guard let maxAge = parts.filter({ $0.range(of: "max-age") != nil }).first else {
            return
        }
        guard let stringValue = maxAge.split(separator: "=").dropFirst().first, let age = Int(String(describing: stringValue)), age > 0 else {
            return
        }
        let data = _data ?? Data()
        let cachedResponse = CachedURLResponse(response: response, data: data, userInfo: nil, storagePolicy: .allowedInMemoryOnly)
        _session?.configuration.urlCache?.storeCachedResponse(cachedResponse, for: _request)
    }

    init(session: URLSession, request: URLRequest, callback: @escaping URLSessionTaskCallback, stub: NetworkStub) {
        self.callback = callback
        if let responseData = stub.responseData {
            switch responseData {
            // If it's just a JSON object, we serialize it to a Data and just set that and we're done
            case let .jsonObject(json):
                _data = try? JSONSerialization.data(withJSONObject: json, options: [])

            case let .string(string):
                _data = string.data(using: .utf8)

            // If it's an array of datas, we just take the first data and the first status code and set the data and response to that
            case let .arrayOfData(datas):
                _data = datas.first?.data
                if let statusCode = datas.first?.statusCode {
                    let url = request.url ?? URL(string: "unknown")!
                    _response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: stub.responseHeaders)
                }
            }
        } else {
            _data = nil
        }

        // Only if the response object was not set before, and if we have a status code do we set the response object here
        // This means that if we have an arrayOfData then that response overrides this one
        if _response == nil, let statusCode = stub.statusCode, let url = request.url {
            _response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: stub.responseHeaders)
        }
        _error = stub.error
        _session = session
        _request = request

        super.init()

        log(level: .verbose, from: self, "created mock for \(request)")
    }
    override func resume() {
        log(level: .verbose, from: self, "resuming mock for \(_request)")
        handleCacheControl()
        callback?(_data, _response, _error)
        callback = nil // just in case someone decides to call resume again
    }
    override func cancel() {
        log(level: .verbose, from: self, "cancelling mock for \(_request)")
        let error = NSError(domain: "MockURLSessionDataTask", code: NSURLErrorCancelled, userInfo: nil)
        callback?(nil, nil, error)
        _error = error as Error
        callback = nil // just in case someone decides to call resume again
    }
    override var response: URLResponse? {
        return self._response
    }
    override var currentRequest: URLRequest? {
        return self._request
    }
    override var error: Error? {
        return self._error
    }
    override func suspend() {
        fatalError("Not implemented. Wouldn't know what to do")
    }
}

enum NetworkStubPath: Hashable, CustomStringConvertible {
    // Partial patch matching
    case path(String)

    // Exact URL matching
    case url(URL)

    var description: String {
        switch self {
        case let .path(path):
            return path
        case let .url(url):
            return url.absoluteString
        }
    }

    static func == (lhs: NetworkStubPath, rhs: NetworkStubPath) -> Bool {
        switch lhs {
        case let .path(a):
            if case let .path(b) = rhs { return a == b } else { return false }
        case let .url(a):
            if case let .url(b) = rhs { return a == b } else { return false }
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .path(path): hasher.combine(path)
        case let .url(url): hasher.combine(url.absoluteString)
        }
    }
}

struct NetworkStub: Equatable, Comparable {
    enum ResponseData: Equatable, CustomStringConvertible {
        // This will set the data in the response to be a JSONObject
        case jsonObject(JSONObject)

        // This will set the data in the response to be a String
        case string(String)

        // This will make successive calls use up the array. So if this contains 3 objects, the first time this stub
        // is matches, it will use the first data/code and that will be removed, etc...
        case arrayOfData([(data: Data, statusCode: Int)])

        static func == (lhs: ResponseData, rhs: ResponseData) -> Bool {
            switch lhs {
            case let .jsonObject(a):
                if case let .jsonObject(b) = rhs { return NSDictionary(dictionary: a).isEqual(b) } else { return false }
            case let .string(a):
                if case let .string(b) = rhs { return a == b } else { return false }
            case let .arrayOfData(a):
                if case let .arrayOfData(b) = rhs {
                    guard a.count == b.count else { return false }
                    for (index, element) in a.enumerated() {
                        guard element.data == b[index].data, element.statusCode == b[index].statusCode else {
                            return false
                        }
                    }
                    return true
                } else {
                    return false
                }
            }
        }

        var description: String {
            switch self {
            case let .jsonObject(a):
                do {
                    let data = try JSONSerialization.data(withJSONObject: a)
                    return String(data: data, encoding: .utf8) ?? "<error decoding json>"
                } catch {
                    return "<error decoding json> \(error)"
                }
            case let .string(a):
                return "STRING: \(a)"
            case let .arrayOfData(a):
                return "ARRAY: \(a)"
            }
        }
    }

    fileprivate var responseData: ResponseData?

    // This statusCode is seperate for now and is only useful if responseData is set to .jsonObject
    fileprivate var statusCode: Int?

    fileprivate var error: Error?

    // This is for path customizations. Setting this will allow you to customize if a stub is called on a request or not
    // Use func applesIf to set this.
    private var predicate: ((URLRequest) -> Bool)?

    // Response headers apply to all invocations of the stub
    fileprivate var responseHeaders: [String: String]?

    fileprivate let path: NetworkStubPath

    init(path: NetworkStubPath) {
        self.path = path
    }

    mutating func returnData(json: JSONObject) {
        responseData = .jsonObject(json)
    }

    mutating func returnData(string: String) {
        responseData = .string(string)
    }

    mutating func returnData(_ data: [(data: Data, statusCode: Int)]) {
        responseData = .arrayOfData(data)
    }

    mutating func returnError(error: Error) {
        self.error = error
    }

    mutating func returnResponse(status: Int, headers: [String: String]? = nil) {
        statusCode = status
        responseHeaders = headers
    }

    fileprivate static func unstubbed(path: NetworkStubPath) -> NetworkStub {
        var stub = NetworkStub(path: path)
        stub.returnData(json: [
            "message": "Path \(path) is not stubbed",
        ])
        stub.returnResponse(status: 501)
        return stub
    }

    mutating func appliesIf(predicate: @escaping (URLRequest) -> Bool) {
        self.predicate = predicate
    }

    fileprivate func proceed(with request: URLRequest) -> Bool {
        return predicate?(request) ?? true
    }

    static func == (lhs: NetworkStub, rhs: NetworkStub) -> Bool {
        if lhs.statusCode != rhs.statusCode {
            return false
        }
        guard let resA = lhs.responseData, let resB = rhs.responseData else {
            return lhs.responseData == nil && rhs.responseData == nil
        }
        return resA == resB
    }

    static func < (lhs: NetworkStub, rhs: NetworkStub) -> Bool {
        return lhs.predicate == nil && rhs.predicate != nil
    }
}

extension NetworkStub: CustomStringConvertible {
    var description: String {
        return "  path: \(path)"
            + "\n    - data: \(responseData as Any)"
            + "\n    - headers: \(responseHeaders as Any)"
            + "\n    - status code: \(statusCode as Any)"
            + "\n    - error: \(error as Any)"
    }
}

private extension String {
    func matches(_ regex: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.count > 0
        } catch {
            return false
        }
    }
}

class StubbedNetworkingProxy: NetworkingProxy {
    private static let sharedLock = NSLock()

    var additionalHeaders: [String: String]?

    let session: URLSession = {
        DefaultNetworkingProxy().session
    }()

    static func insert<K>(in dictionary: inout [K: [NetworkStub]], key: K, stub: NetworkStub) {
        guard var stubs = dictionary[key], !stubs.contains(stub) else {
            dictionary[key] = [stub]
            return
        }
        stubs.append(stub)
        stubs.sort()
        dictionary[key] = stubs
    }

    static func replace<K>(in dictionary: inout [K: [NetworkStub]], key: K, stub: NetworkStub, with newStub: NetworkStub) {
        guard var stubs = dictionary[key] else { return }
        guard let index = stubs.enumerated().filter({ $0.element == stub }).first?.offset else { return }
        stubs.remove(at: index)
        stubs.append(newStub)
        stubs.sort()
        dictionary[key] = stubs
    }

    static func addStub(_ stub: NetworkStub) {
        log(level: .verbose, "\n\(stub)")

        StubbedNetworkingProxy.sharedLock.lock()
        defer { StubbedNetworkingProxy.sharedLock.unlock() }

        switch stub.path {
        case let .url(url):
            insert(in: &urls, key: url, stub: stub)
        case let .path(path):
            let parts = path.components(separatedBy: "*")
            let path = parts.joined(separator: "(.*)")
            insert(in: &paths, key: path, stub: stub)
        }
    }

    static func removeStubs() {
        urls.removeAll(keepingCapacity: false)
        paths.removeAll(keepingCapacity: false)
    }

    static var urls: [URL: [NetworkStub]] = [:]
    static var paths: [String: [NetworkStub]] = [:]

    func dataTask(
        for session: URLSession,
        request: URLRequest,
        completion: URLSessionTaskCallback?
    ) -> URLSessionDataTask {
        guard let url = request.url, let completion = completion else {
            return URLSessionDataTask()
        }

        StubbedNetworkingProxy.sharedLock.lock()
        defer { StubbedNetworkingProxy.sharedLock.unlock() }

        // Check if there're exact matches on this URL. If there are, first check if we are allowed
        // to proceed with it (defaults to true) and then return a mock data task
        for stub in type(of: self).urls[url] ?? [] {
            log(level: .debug, from: self, "using url stub: \(stub.path) for \(request)")
            if stub.proceed(with: request) {
                // Incase we are an arrayOfData, we need to remove the first element since it is now "used up" but only if there are more than 1 elements
                defer {
                    if case var .arrayOfData(datas)? = stub.responseData {
                        if datas.count > 1 {
                            datas.remove(at: 0)
                            var newStub = stub
                            newStub.returnData(datas)
                            type(of: self).replace(in: &type(of: self).urls, key: url, stub: stub, with: newStub)
                            log(level: .debug, from: self, "removed url stub: \(stub.path) for \(request)")
                        }
                    }
                }
                return MockURLSessionDataTask(session: session, request: request, callback: completion, stub: stub)
            }
        }

        // If we do not have an exact URL match, check if any of the paths match (so contained in URL)
        let dictionary = type(of: self).paths
        let sortedPaths = dictionary.keys.sorted { $0.count > $1.count }
        for path in sortedPaths where url.absoluteString.matches(path) {
            for stub in dictionary[path] ?? [] {
                log(level: .debug, from: self, "using path stub: \(stub.path) for \(request)")
                if stub.proceed(with: request) {
                    // Incase we are an arrayOfData, we need to remove the first element since it is now "used up" but only if there are more than 1 elements
                    defer {
                        if case var .arrayOfData(datas)? = stub.responseData {
                            if datas.count > 1 {
                                datas.remove(at: 0)
                                var newStub = stub
                                newStub.returnData(datas)
                                type(of: self).replace(in: &type(of: self).paths, key: path, stub: stub, with: newStub)
                                log(level: .debug, from: self, "removed path stub: \(stub.path) for \(request)")
                            }
                        }
                    }
                    return MockURLSessionDataTask(session: session, request: request, callback: completion, stub: stub)
                }
            }
        }

        log(level: .debug, from: self, "requst \(request) not stubbed")
        // This URL is not stubbed
        return MockURLSessionDataTask(session: session, request: request, callback: completion, stub: .unstubbed(path: .url(url)))
    }
}
