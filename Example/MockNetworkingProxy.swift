//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
@testable import SchibstedAccount

extension NetworkStub {
    static let userID = "mockUserID"

    static func clientAccessToken() -> NetworkStub {
        var stub = NetworkStub(path: .path(Router.oauthToken.path))
        stub.returnData(json: [
            "access_token": "mockClientAccessToken",
            "refresh_token": "mockClientRefreshToken",
            "token_type": "Bearer",
            "expires_in": 604_800,
            "user_id": false,
            "is_admin": false,
            "server_time": 1_487_136_977,
        ])
        stub.returnResponse(status: 200)
        stub.appliesIf { request in
            guard let body = request.httpBody, let string = String(data: body, encoding: .utf8) else {
                return false
            }
            return string.contains("client_credentials")
        }
        return stub
    }

    static func oauthToken(path: NetworkStubPath) -> NetworkStub {
        var stub = NetworkStub(path: path)
        stub.returnData(json: [
            "access_token": "mockUserAccessToken",
            "refresh_token": "mockUserRefreshToken",
            "id_token": "mockUserIDToken",
            "user_id": "mockUserID",
            "token_type": "Bearer",
            "expires_in": 300,
            "scope": "openid",
        ])
        stub.returnResponse(status: 200)
        return stub
    }

    static func identifierStatus(path: NetworkStubPath) -> NetworkStub {
        var stub = NetworkStub(path: path)
        stub.returnData(json: [
            "data": [
                "exists": true,
                "available": true,
                "verified": true,
            ],
        ])
        stub.returnResponse(status: 200)
        return stub
    }

    static func userSignup() -> NetworkStub {
        var stub = NetworkStub(path: .path(Router.signup.path))
        stub.returnData(json: [
            "data": [
                "email": "austin@yeahbaby.com",
            ],
        ])
        stub.returnResponse(status: 201)
        return stub
    }

    static func passwordless() -> NetworkStub {
        var stub = NetworkStub(path: .path(Router.passwordlessStart.path))
        stub.returnData(json: [
            "passwordless_token": "token",
        ])
        stub.returnResponse(status: 200)
        return stub
    }

    static func profile() -> NetworkStub {
        let givenName = "Luffy"
        let familyName = "Monkey D"
        var stub = NetworkStub(path: .path(Router.profile(userID: self.userID).path))
        stub.returnData(json: [
            "data": [
                "name": [
                    "givenName": givenName,
                    "familyName": familyName,
                    "formatted": "\(String(describing: givenName)) \(String(describing: familyName))",
                ],
            ],
        ])
        stub.returnResponse(status: 200)
        return stub
    }

    static func agreementsStatus() -> NetworkStub {
        var stub = NetworkStub(path: .path(Router.agreementsStatus(userID: self.userID).path))
        stub.returnData(json: [
            "data": [
                "agreements": [
                    "platform": true,
                    "client": true,
                ],
            ],
        ])
        stub.returnResponse(status: 200)
        return stub
    }

    static func acceptAgreements() -> NetworkStub {
        var stub = NetworkStub(path: .path(Router.acceptAgreements(userID: self.userID).path))
        stub.returnData(json: [
            "data": [
                "result": true,
            ],
        ])
        stub.returnResponse(status: 200)
        return stub
    }

    static func fetchTerms() -> NetworkStub {
        var stub = NetworkStub(path: .path(Router.terms.path))
        stub.returnData(json: [
            "data": [
                "platform_privacy_url": "http//platform_privacy_url",
                "platform_terms_url": "http//platform_terms_url",
                "privacy_url": "http//privacy_url",
                "terms_url": "http//terms_url",
            ],
        ])
        stub.returnResponse(status: 200)
        return stub
    }

    static func tokenExchange() -> NetworkStub {
        var stub = NetworkStub(path: .path(Router.exchangeToken.path))
        stub.returnData(json: [
            "data": [
                "code": "192.168.0.1",
            ],
        ])
        stub.returnResponse(status: 200)
        return stub
    }

    static func requiredFields() -> NetworkStub {
        var stub = NetworkStub(path: .path(Router.requiredFields(userID: self.userID).path))
        stub.returnData(json: [
            "data": [
                "requiredFields": [
                    RequiredField.birthday.rawValue,
                    RequiredField.familyName.rawValue,
                    RequiredField.givenName.rawValue,
                ],
            ],
        ])
        stub.returnResponse(status: 200)
        return stub
    }

    static func client() -> NetworkStub {
        var stub = NetworkStub(path: .path(Router.client(clientID: ClientConfiguration.current.clientID).path))
        stub.returnData(json: [
            "data": [
                "fields": [
                    ClientRequiredFieldsKey.birthday.rawValue: true,
                    ClientRequiredFieldsKey.names.rawValue: true,
                ],
            ],
        ])
        stub.returnResponse(status: 200)
        return stub
    }
}

extension UIApplication {
    static var offlineMode: Bool {
        get {
            return (UIApplication.shared.delegate as! AppDelegate).offlineMode // swiftlint:disable:this force_cast
        }
        set(value) {
            (UIApplication.shared.delegate as! AppDelegate).offlineMode = value // swiftlint:disable:this force_cast
            if value {
                Networking.proxy = StubbedNetworkingProxy()
                StubbedNetworkingProxy.setupStubs()
            } else {
                Networking.proxy = DefaultNetworkingProxy()
            }
        }
    }
}

extension StubbedNetworkingProxy {
    static func setupStubs() {
        StubbedNetworkingProxy.addStub(.passwordless())
        StubbedNetworkingProxy.addStub(.oauthToken(path: .path(Router.validate.path)))
        StubbedNetworkingProxy.addStub(.oauthToken(path: .path(Router.oauthToken.path)))
        StubbedNetworkingProxy.addStub(.clientAccessToken())
        StubbedNetworkingProxy.addStub(.userSignup())
        StubbedNetworkingProxy.addStub(.profile())
        StubbedNetworkingProxy.addStub(.tokenExchange())
        StubbedNetworkingProxy.addStub(.identifierStatus(path: .path(Router.identifierStatus(connection: .sms, identifierInBase64: "*").path)))
        StubbedNetworkingProxy.addStub(.identifierStatus(path: .path(Router.identifierStatus(connection: .email, identifierInBase64: "*").path)))
        StubbedNetworkingProxy.addStub(.agreementsStatus())
        StubbedNetworkingProxy.addStub(.acceptAgreements())
        StubbedNetworkingProxy.addStub(.fetchTerms())
        StubbedNetworkingProxy.addStub(.requiredFields())
        StubbedNetworkingProxy.addStub(.client())
    }
}
