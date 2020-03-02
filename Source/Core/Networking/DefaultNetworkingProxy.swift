//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class DefaultNetworkingProxy: NetworkingProxy {
    var additionalHeaders: [String: String]?

    let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        config.httpAdditionalHeaders = [
            Networking.Header.userAgent.rawValue: UserAgent().value,
            Networking.Header.xOIDC.rawValue: "true",
            Networking.Header.sdkVersion.rawValue: sdkVersion,
            Networking.Header.sdkType.rawValue: "ios",
        ]
        return URLSession(configuration: config)
    }()

    func dataTask(
        for session: URLSession,
        request: URLRequest,
        completion: URLSessionTaskCallback?
    ) -> URLSessionDataTask {
        if let completion = completion {
            return session.dataTask(with: request, completionHandler: completion)
        }
        return session.dataTask(with: request)
    }
}
