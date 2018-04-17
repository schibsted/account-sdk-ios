//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

enum PasswordlessTokenStoreError: Error {
    case noData(Connection)
    case invalidData(Connection, String)
    case invalidIdentifier(Connection, String)
}

extension PasswordlessTokenStoreError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .noData(connection):
            return "No data for connection \(connection)"
        case let .invalidData(connection, data):
            return "Invalid data for connection \(connection). Data = \(data)"
        case let .invalidIdentifier(connection, identifier):
            return "Invalid identifier '\(identifier)' for \(connection)"
        }
    }
}

extension PasswordlessTokenStoreError: ClientErrorConvertible {
    var clientError: ClientError {
        return .unexpected(self)
    }
}

struct PasswordlessTokenStore {
    private struct Key: CustomStringConvertible {
        fileprivate static let prefix = "passwordless-token"
        let key: String
        init(_ value: String) {
            self.key = [Key.prefix, value].joined(separator: ".")
        }
        init(_ connection: Connection) {
            self.init(String(describing: connection))
        }

        var description: String {
            return self.key
        }
    }

    static func setData(token: PasswordlessToken, identifier: Identifier, for connection: Connection) {
        let stringToStore = "\(token):" + identifier.serializedString
        let key = Key(connection)
        Settings.setValue(stringToStore, forKey: String(describing: key))
        log("\(key) -> \(stringToStore)")
    }

    static func getData(for connection: Connection) throws -> (identifier: Identifier, token: PasswordlessToken) {
        let key = Key(connection)

        guard let data = Settings.value(forKey: String(describing: key)) as? String else {
            throw PasswordlessTokenStoreError.noData(connection)
        }

        let components = data.components(separatedBy: ":")
        guard let token = components.first, !token.isEmpty else {
            throw PasswordlessTokenStoreError.invalidData(connection, data)
        }

        let serelizedIdentifier = components.dropFirst().joined(separator: ":")
        guard let identifier = Identifier(serializedString: serelizedIdentifier) else {
            throw PasswordlessTokenStoreError.invalidIdentifier(connection, serelizedIdentifier)
        }

        return (identifier: identifier, token: PasswordlessToken(token))
    }

    static func clear() {
        Settings.clearWhere(prefix: Key.prefix)
    }
}
