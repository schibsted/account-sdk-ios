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
        let stringToStore: String

        switch identifier {
        case let .email(email):
            stringToStore = "\(email.normalizedString):\(token)"
        case let .phone(phoneNumber):
            let (normalizedCountryCode, normalizedNumber) = phoneNumber.normalizedValue
            stringToStore = "\(normalizedCountryCode)-\(normalizedNumber):\(token)"
        }

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

        guard components.count == 2 && !components[0].isEmpty && !components[1].isEmpty else {
            throw PasswordlessTokenStoreError.invalidData(connection, data)
        }

        let identifierString = components[0]
        let token = components[1]

        var maybeIdentifier: Identifier?
        switch connection {
        case .email:
            if let email = EmailAddress(identifierString) {
                maybeIdentifier = Identifier(email)
            }
        case .sms:
            let phoneComponents = identifierString.components(separatedBy: "-")

            guard phoneComponents.count == 2 && !phoneComponents[0].isEmpty && !phoneComponents[1].isEmpty else {
                throw PasswordlessTokenStoreError.invalidData(connection, data)
            }

            let countryCode = phoneComponents[0]
            let number = phoneComponents[1]

            if let phone = PhoneNumber(countryCode: countryCode, number: number) {
                maybeIdentifier = Identifier(phone)
            }
        }

        guard let identifier = maybeIdentifier else {
            throw PasswordlessTokenStoreError.invalidIdentifier(connection, identifierString)
        }

        return (identifier: identifier, token: PasswordlessToken(token))
    }

    static func clear() {
        Settings.clearWhere(prefix: Key.prefix)
    }
}
