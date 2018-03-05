//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Mockingjay

struct Builders {

    static func load(file name: String, status: Int) throws -> (URLRequest) -> Response {
        let bundle = Bundle(for: TestingUser.self)

        guard let path = bundle.path(forResource: name, ofType: "json") else {
            throw NSError(domain: "Must specify a file name that exists in the test bundle", code: 0, userInfo: nil)
        }

        let data = (try? Data(contentsOf: URL(fileURLWithPath: path))) ?? Data()

        return { request -> Response in
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return .success(response, .content(data))
        }
    }

    static func sequentialBuilder(_ builders: [(URLRequest) -> Response]) -> (URLRequest) -> Response {
        let max = builders.count
        var count = 0
        return { request -> Response in
            let builder = builders[count]
            if count < max - 1 {
                count += 1
            }
            return builder(request)
        }
    }

    static func load(string: String, status: Int) -> (URLRequest) -> Response {

        let data = string.data(using: String.Encoding.utf8) ?? Data()

        return { request -> Response in
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return .success(response, .content(data))
        }
    }
}
