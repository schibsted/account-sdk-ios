//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/// Callback that has no value as a success and a `ClientError` on failure
public typealias NoValueCallback = (Result<NoValue, ClientError>) -> Void

/// Callback that returns a string
public typealias StringResultCallback = (Result<String, ClientError>) -> Void

/// Callback that returns an URL
public typealias URLResultCallback = (Result<URL, ClientError>) -> Void

/// Callback that returns a boolean
public typealias BoolResultCallback = (Result<Bool, ClientError>) -> Void

/// Callback that returns the status of an identifier
public typealias IdentifierStatusResultCallback = (Result<IdentifierStatus, ClientError>) -> Void

/// Callback that returns the terms and conditions links
/// - seeAlso: `IdentityManager.fetchTerms`
public typealias TermsResultCallback = (Result<Terms, ClientError>) -> Void

/// Callback that returns information about the your client
/// - seeAlso: `IdentityManager.fetchClient`
public typealias ClientResultCallback = (Result<Client, ClientError>) -> Void

/// Callback that returns the required fields
/// -seeAlso `IdentityManager.requiredFields
/// -seeAlso 'UserProfileAPI.requiredFields
public typealias RequiredFieldsResultCallback = (Result<[RequiredField], ClientError>) -> Void

/// Callback that returns the user's assets
public typealias UserAssetsResultCallback = (Result<[UserAsset], ClientError>) -> Void
