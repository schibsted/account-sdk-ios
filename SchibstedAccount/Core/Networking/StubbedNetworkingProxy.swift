//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class MockURLSessionDataTask: URLSessionDataTask {
    var callback: URLSessionTaskCallback?
    let _data: Data?
    let _response: URLResponse?
    var _error: Error?
    init(request: URLRequest, callback: @escaping URLSessionTaskCallback, stub: NetworkStub) {
        self.callback = callback
        if let jsonData = stub.jsonData {
            self._data = try? JSONSerialization.data(withJSONObject: jsonData, options: [])
        } else {
            self._data = nil
        }
        if let statusCode = stub.statusCode, let url = request.url {
            self._response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        } else {
            self._response = nil
        }
        self._error = nil
    }
    override func resume() {
        self.callback?(self._data, self._response, self._error)
        self.callback = nil
    }
    override func cancel() {
        let error = NSError(domain: "MockURLSessionDataTask", code: NSURLErrorCancelled, userInfo: nil)
        self.callback?(nil, nil, error)
        self._error = error as Error
    }
    override var response: URLResponse? {
        return self._response
    }
    override var error: Error? {
        return self._error
    }
    override func suspend() {
        fatalError("Not implemented. Wouldn't know what to do")
    }
}

enum NetworkStubPath: Hashable, CustomStringConvertible {
    case path(String)
    case url(URL)
    case `default`

    var description: String {
        switch self {
        case let .path(path):
            return path
        case let .url(url):
            return url.absoluteString
        case .default:
            return "*"
        }
    }

    static func == (lhs: NetworkStubPath, rhs: NetworkStubPath) -> Bool {
        switch lhs {
        case let .path(a):
            if case let .path(b) = rhs { return a == b } else { return false }
        case let .url(a):
            if case let .url(b) = rhs { return a == b } else { return false }
        case .default:
            if case .default = rhs { return true } else { return false }
        }
    }

    var hashValue: Int {
        switch self {
        case let .path(path): return path.hashValue
        case let .url(url): return url.absoluteString.hashValue
        case .default: return "*".hashValue
        }
    }
}

struct NetworkStub: Equatable, Comparable {
    var jsonData: JSONObject?
    var statusCode: Int?
    var predicate: ((URLRequest) -> Bool)?
    let path: NetworkStubPath

    init(path: NetworkStubPath) {
        self.path = path
    }

    mutating func returnData(json: JSONObject) {
        self.jsonData = json
    }

    mutating func returnResponse(status: Int) {
        self.statusCode = status
    }

    static func unstubbed(path: NetworkStubPath) -> NetworkStub {
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

    func proceed(with request: URLRequest) -> Bool {
        return self.predicate?(request) ?? true
    }

    static func == (lhs: NetworkStub, rhs: NetworkStub) -> Bool {
        if lhs.statusCode != rhs.statusCode {
            return false
        }
        guard let jsonA = lhs.jsonData, let jsonB = rhs.jsonData else {
            return lhs.jsonData == nil && rhs.jsonData == nil
        }
        return NSDictionary(dictionary: jsonA).isEqual(to: jsonB)
    }

    static func < (lhs: NetworkStub, rhs: NetworkStub) -> Bool {
        return lhs.predicate == nil && rhs.predicate != nil
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

    var session: URLSession {
        return .shared
    }

    static func insert<K>(in dictionary: inout SynchronizedDictionary<K, [NetworkStub]>, key: K, stub: NetworkStub) {
        dictionary.getAndSet(key: key) { stubs in
            guard var stubs = stubs else {
                return [stub]
            }
            guard !stubs.contains(stub) else {
                return stubs
            }
            stubs.append(stub)
            stubs.sort()
            return stubs
        }
    }

    static func addStub(_ stub: NetworkStub) {
        switch stub.path {
        case let .url(url):
            self.insert(in: &self.urls, key: url, stub: stub)
        case let .path(path):
            let parts = path.components(separatedBy: "*")
            let path = parts.joined(separator: "(.*)")
            self.insert(in: &self.paths, key: path, stub: stub)
        case .default:
            DispatchQueue.global().sync {
                self.defaultStubs.append(stub)
                self.defaultStubs.sort()
            }
        }
    }

    static var urls = SynchronizedDictionary<URL, [NetworkStub]>()
    static var paths = SynchronizedDictionary<String, [NetworkStub]>()
    static var defaultStubs: [NetworkStub] = []

    func dataTask(
        for _: URLSession,
        request: URLRequest,
        completion: URLSessionTaskCallback?
    ) -> URLSessionDataTask {

        guard let url = request.url, let completion = completion else {
            return URLSessionDataTask()
        }

        for stub in type(of: self).urls[url] ?? [] {
            if stub.proceed(with: request) {
                return MockURLSessionDataTask(request: request, callback: completion, stub: stub)
            }
        }

        let dictionary = type(of: self).paths.take()
        let sortedPaths = dictionary.keys.sorted { $0.count > $1.count }
        for path in sortedPaths where url.absoluteString.matches(path) {
            for stub in dictionary[path] ?? [] {
                if stub.proceed(with: request) {
                    return MockURLSessionDataTask(request: request, callback: completion, stub: stub)
                }
            }
        }

        let defaultStubs = DispatchQueue.global().sync {
            return type(of: self).defaultStubs
        }

        for stub in defaultStubs {
            if stub.proceed(with: request) {
                return MockURLSessionDataTask(request: request, callback: completion, stub: stub)
            }
        }

        return MockURLSessionDataTask(request: request, callback: completion, stub: .unstubbed(path: .url(url)))
    }
}
