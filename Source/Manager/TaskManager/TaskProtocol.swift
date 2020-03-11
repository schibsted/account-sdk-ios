//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

protocol TaskProtocol: AnyObject {
    associatedtype SuccessType
    func execute(completion: @escaping (Result<SuccessType, ClientError>) -> Void)
    func shouldRefresh(result: Result<SuccessType, ClientError>) -> Bool
    func didCancel()
}

extension TaskProtocol {
    func shouldRefresh(result: Result<SuccessType, ClientError>) -> Bool {
        if case let .failure(error) = result {
            if case let .networkingError(NetworkingError.unexpectedStatus(status, _)) = error, status == 401 {
                return true
            }
        }
        return false
    }

    func didCancel() {}
}
