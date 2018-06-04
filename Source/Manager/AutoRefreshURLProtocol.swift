//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class AutoRefreshTask: TaskProtocol {
    #if DEBUG
        static var counter = AtomicInt(0)
    #endif

    typealias SuccessType = (data: Data?, response: URLResponse?, error: Error?)

    private static let session: URLSession = {
        URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
    }()

    weak var user: User?
    var request: URLRequest
    var dataTask: URLSessionDataTask?

    init(request: URLRequest, user: User) {
        self.request = request
        self.user = user
        #if DEBUG
            AutoRefreshTask.counter.getAndIncrement()
        #endif
    }

    deinit {
        #if DEBUG
            AutoRefreshTask.counter.getAndDecrement()
        #endif
    }

    func execute(completion: @escaping (Result<SuccessType, ClientError>) -> Void) {
        guard let accessToken = self.user?.tokens?.accessToken else {
            completion(.failure(.invalidUser))
            return
        }
        var newRequest = self.request
        newRequest.setValue(nil, forHTTPHeaderField: AutoRefreshURLProtocol.key)
        newRequest.addValue(accessToken.bearer, forHTTPHeaderField: "Authorization")

        self.dataTask = Networking.dataTask(for: AutoRefreshTask.session, request: newRequest, completion: { data, response, error in
            completion(.success((data, response, error)))
        })

        self.dataTask?.resume()
    }

    func didCancel() {
        self.dataTask?.cancel()
    }

    func shouldRefresh(result: Result<SuccessType, ClientError>) -> Bool {
        if case let .success(value) = result, value.response?.isAuthorizationFailure() ?? false {
            return true
        }
        return false
    }
}

class AutoRefreshURLProtocol: URLProtocol {
    #if DEBUG
        static var counter = AtomicInt(0)
    #endif

    /*
     This is here so that each instantiation of the SDK has a different value associated with it.
     Why: so that we can have a truly private key for where we want to store the UserID and so that a
     "client" of the SDK can't "inject" a user ID in.
     */
    static let key: String = {
        let uuid = UUID().uuidString
        return "\(self)" + uuid[..<uuid.index(uuid.startIndex, offsetBy: 6)]
    }()

    static var userTaskManagerMap: [Int: TaskManager] = [:]

    var taskHandle: TaskHandle?

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        #if DEBUG
            AutoRefreshURLProtocol.counter.getAndIncrement()
        #endif
    }

    deinit {
        #if DEBUG
            AutoRefreshURLProtocol.counter.getAndDecrement()
        #endif
    }

    override class func canInit(with _: URLRequest) -> Bool {
        // If this protocol is being used then we intercept all requests and then do the necessary injections
        // in the startLoading function
        return true
    }

    override func startLoading() {
        log(from: self, self.request)
        guard let userInstanceAddressString = request.allHTTPHeaderFields?[type(of: self).key],
            let userInstanceAddressInt = Int(userInstanceAddressString),
            let user = User.globalStore[userInstanceAddressInt]
        else {
            self.client?.urlProtocol(self, didFailWithError: ClientError.invalidUser)
            return
        }

        let taskManager: TaskManager
        let key = ObjectIdentifier(user).hashValue
        if let taskManagerForUser = type(of: self).userTaskManagerMap[key] {
            taskManager = taskManagerForUser
        } else {
            taskManager = TaskManager(for: user)
            AutoRefreshURLProtocol.userTaskManagerMap[key] = taskManager
            user.willDeinit.register {
                AutoRefreshURLProtocol.userTaskManagerMap.removeValue(forKey: key)
            }.descriptionText = "\(type(of: self))"
        }

        self.taskHandle = taskManager.add(task: AutoRefreshTask(request: self.request, user: user)) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            do {
                let tuple = try result.materialize()
                if let response = tuple.response {
                    strongSelf.client?.urlProtocol(strongSelf, didReceive: response, cacheStoragePolicy: .allowed)
                }
                if let data = tuple.data {
                    strongSelf.client?.urlProtocol(strongSelf, didLoad: data)
                }
                if let error = tuple.error {
                    throw error
                }
                strongSelf.client?.urlProtocolDidFinishLoading(strongSelf)
            } catch {
                log(level: .debug, from: self, "got error \(error) with NSError.code = \((error as NSError).code)")
                strongSelf.client?.urlProtocol(strongSelf, didFailWithError: error)
                strongSelf.client?.urlProtocolDidFinishLoading(strongSelf)
            }
        }
    }

    override func stopLoading() {
        log(from: self, self.request)
        self.taskHandle?.cancel()
    }
}
