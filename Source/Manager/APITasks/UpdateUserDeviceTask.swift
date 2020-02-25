//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class UpdateUserDeviceTask: TaskProtocol {
    private weak var user: User?
    private var device: UserDevice

    init(user: User?, device: UserDevice) {
        self.user = user
        self.device = device
    }

    func execute(completion: @escaping NoValueCallback) {
        guard let user = self.user, let tokens = user.tokens else {
            completion(.failure(.invalidUser))
            return
        }

        user.api.updateUserDevice(
            oauthToken: tokens.accessToken,
            device: device
        ) { [weak self] result in
            guard self?.user != nil else {
                completion(.failure(.invalidUser))
                return
            }
            switch result {
            case .success:
                completion(.success(()))
            case let .failure(error):
                completion(.failure(ClientError(error)))
            }
        }
    }
}
