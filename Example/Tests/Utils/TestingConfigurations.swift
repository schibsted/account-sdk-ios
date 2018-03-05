//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
@testable import SchibstedAccount

extension ClientConfiguration {
    static let testing = ClientConfiguration(
        serverURL: URL(string: "http://localhost:5050")!,
        clientID: "123",
        clientSecret: "123",
        appURLScheme: "blah.123"
    )
}

extension IdentityUIConfiguration {
    static let testing = IdentityUIConfiguration(
        clientConfiguration: .testing,
        theme: .default
    )
}
