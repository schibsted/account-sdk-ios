//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

private extension Array where Element: Hashable {
    func duplicatesRemoved() -> [Element] {
        return Array(Set(self))
    }
}

/**
 This delegate informs you of changes within the `IdentityManager`.
 */
public protocol IdentityManagerDelegate: class {
    /**
     Informs you when the state of `IdentityManager.currentUser` changes

     - SeeAlso: `UserDelegate.user(_:didChangeStateTo:)`
     */
    func userStateChanged(_ state: UserState)
}

/**
 This manager provides access to various auth related APIs and manages the creation and persistence of an internal `User` object that
 can be accessed through `IdentityManager.currentUser`.

 A number of methods of creating a user exist within this manager. They include:
 1. Passwordless login APIs (`IdentityManager.sendCode(...)`)
 1. Password login APIs (`IdentityManager.login(...)`)
 1. Signup APIs (`IdentityManager.signup(...)`)
 1. APIs to access client specific information

 The general approach is to first create an IdentityManager with a `ClientConfiguration`. After that you may check if there already
 is a user that was previously persisted. This can be checked via `IdentityManager.currentUser`'s `User.state` which will tell you if the internal
 user is in a logged in or logged out state. In order to comply with privacy regulations, you also need to make sure that the user accepts any update to terms
 and conditions that may have been issued since the user's last visit: see `User`'s documentation for more details on how to do that.

 The objective of the identity manager is to create a user object. There should be no need to keep an identity manager lying around once
 you have a reference to the internal user object.

 ### Authorization code vs one-time code

 There are two "code" validation APIs in the manager. One of them operates on one time codes that are explicitly send to an `Identifier`
 using `IdentityManager.sendCode(...)` to start a passwordless login process. The other is an OAuth-related authroization code, which
 is not explicily requested. The current use-case for authorization code validation is after a signup process, when a user verifies
 their email. Or after an unverified identifier tries to login.

 ### After logging in

 After you successfully login by either the passwordless or password APIs, it is recommended that you check the profile status of your
 user object. This means checking if there are updated terms and conditions that need to be accepted or if there are required fields
 that need to be updated. These can both be done via `User.Agreements.status(...)` and `User.Profile.requiredFields(...)`.

 ### User persistence

 If the `persistUser` parameter passed to the `IdentityManager`'s methods is `true`, the user that is internally managed by an identity manager is also
 persisted in your keychain for maintaing logged in and logged out state. Therefore, once a user is made valid, the manager persists the data necessary to
 recreate the user for a later session.

 Currently the keychain user is a singleton. So the last user that is "validated" will be persisted. And the last user that is persisted
 will be the one that is loaded by a new instance of the `IdentityManager`.

 ### Scopes

 Some of the functions take a scope parameter. This is related to OAuth scopes. If you want to add the ability to specify custom scopes or you
 want access to some already available predefined scopes, then you'll have to send a support request to support@spid.no

 ### **Support**

 The visual login via the `IdentityUI` is the recommended approach to creating a `User`. This `IdentityManager` should just be
 used to check if there's already an existing user.

 */
public class IdentityManager: IdentityManagerProtocol {
    private static let defaultScopes = ["openid"]

    /**
     The delegate that will receive events related to the manager's state.
     */
    public weak var delegate: IdentityManagerDelegate?

    /**
     The user managed by this manager

     This user object is persisted in the keychain so that when you initialize an identity manager again, you may
     just resume the previously saved user session.

     Users are persisted after any successful login process.
     */
    public internal(set) var currentUser: User

    private let api: IdentityAPI

    /**
     The client configuration used to create the manager
     */
    public let clientConfiguration: ClientConfiguration

    /**
     Gives you access to SPiD web flow routes.

     Where relevent, these can typically be used with `User.Auth.webSessionURL(...)` to create a web session on a SPiD page
     where a user is considered as logged in.
     */
    public let routes: WebSessionRoutes

    /**
     Initializes the identity manager.

     If there is a valid user in the keychain then that will be loaded in, else you will have to create a user
     using one of the aformentioned methods.

     - parameter clientConfiguration: defines your configuration
     */
    public required init(clientConfiguration: ClientConfiguration) {
        self.clientConfiguration = clientConfiguration
        self.api = IdentityAPI(basePath: clientConfiguration.serverURL)
        self.routes = WebSessionRoutes(clientConfiguration: clientConfiguration)

        self.currentUser = User(clientConfiguration: clientConfiguration)
        self.currentUser.delegate = self

        try? self.currentUser.loadStoredTokens()

        log(from: self, "user: \(self.currentUser)")
    }

    private func dispatchIfSelf(_ block: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            block()
        }
    }

    /**
     Starts a passwordless login flow with `Identifier` as the basis of where to send the one time code to

     One time code passwordless authentication involves 2 steps. First this method is called to send a code
     to an identifier. This code has to be extracted seperately by the owner of the identifier and then it
     can be used with `validate(oneTimeCode:for:completion:)` to create a valid user

     - parameter identifier: can be either email or phone number
     - parameter completion: callback that is called after the code is sent
     */
    public func sendCode(to identifier: Identifier, completion: @escaping NoValueCallback) {
        log(from: self, identifier)

        let locale = self.clientConfiguration.locale
        let localeID = Locale.canonicalLanguageIdentifier(from: locale.identifier)

        let completion = { [weak self] (result: Result<PasswordlessToken, ClientError>) in
            log(from: self, result)

            switch result {
            case let .success(token):
                PasswordlessTokenStore.setData(
                    token: token,
                    identifier: identifier,
                    for: identifier.connection
                )

                self?.dispatchIfSelf {
                    completion(.success(()))
                }
            case let .failure(error):
                self?.dispatchIfSelf {
                    completion(.failure(error))
                }
            }
        }

        self.api.startPasswordless(
            clientID: self.clientConfiguration.clientID,
            clientSecret: self.clientConfiguration.clientSecret,
            locale: localeID,
            identifier: identifier.normalizedString,
            connection: identifier.connection,
            completion: completion
        )
    }

    /**
     Resends the code that was tried previously with `sendCode(...)`.

     - parameter identifier: can be either email or phone number
     - parameter completion: callback that is called after the code has been resent

     - SeeAlso: `sendCode(...)`
     */
    public func resendCode(to identifier: Identifier, completion: @escaping NoValueCallback) {
        log(from: self, identifier)
        let passwordlessToken: PasswordlessToken
        do {
            let data = try PasswordlessTokenStore.getData(for: identifier.connection)
            guard data.identifier == identifier else {
                throw ClientError.unexpectedIdentifier(actual: identifier, expected: data.identifier.normalizedString)
            }
            passwordlessToken = data.token
        } catch {
            return self.dispatchIfSelf {
                completion(.failure(ClientError(error)))
            }
        }

        let locale = self.clientConfiguration.locale
        let localeID = Locale.canonicalLanguageIdentifier(from: locale.identifier)

        self.api.resendCode(
            clientID: self.clientConfiguration.clientID,
            clientSecret: self.clientConfiguration.clientSecret,
            passwordlessToken: passwordlessToken,
            locale: localeID
        ) { [weak self] result in
            log(from: self, result)

            switch result {
            case let .success(token):
                if token == passwordlessToken {
                    self?.dispatchIfSelf {
                        completion(.success(()))
                    }
                } else {
                    self?.dispatchIfSelf {
                        completion(.failure(.unexpected(GenericError.Unexpected("passwordless tokens mismatch"))))
                    }
                }
            case let .failure(error):
                self?.dispatchIfSelf {
                    completion(.failure(error))
                }
            }
        }
    }

    /**
     Used after a call to `sendCode(...)` to validate the one time code that was sent to an identifier.

     - parameter oneTimeCode: the code sent to identifier
     - parameter identifier: the user's identifier. Should match the one used in `sendCode(...)`
     - parameter scopes: array of scopes you want the token to contain
     - parameter persistUser: whether the login status should be persistent on app's relaunches
     - parameter completion: the callback that is called after the one time code is checked
     */
    public func validate(oneTimeCode: String, for identifier: Identifier, scopes: [String] = [], persistUser: Bool, completion: @escaping NoValueCallback) {
        log(from: self, "code: \(oneTimeCode), identifier: \(identifier)")
        let passwordlessToken: PasswordlessToken
        do {
            let data = try PasswordlessTokenStore.getData(for: identifier.connection)
            guard data.identifier == identifier else {
                throw ClientError.unexpectedIdentifier(actual: identifier, expected: data.identifier.normalizedString)
            }
            passwordlessToken = data.token
        } catch {
            return self.dispatchIfSelf {
                completion(.failure(ClientError(error)))
            }
        }

        log(from: self, "passwordlessToken \(String(describing: passwordlessToken).gut())")

        self.api.validateCode(
            clientID: self.clientConfiguration.clientID,
            clientSecret: self.clientConfiguration.clientSecret,
            identifier: identifier.normalizedString,
            connection: identifier.connection,
            code: oneTimeCode,
            passwordlessToken: passwordlessToken,
            scope: (scopes + IdentityManager.defaultScopes).duplicatesRemoved()
        ) { [weak self] result in
            self?.finishLogin(result: result, persistUser: persistUser, completion: completion)
        }
    }

    /**
     Used to validate an authorization code

     `sendCode(...)` must have been called before. The difference between this overload
     and the one that takes an explicit identifier is that this will try and validate against any identifier
     that was previously used (during a single session) and succeed if any succeed.

     - parameter oneTimeCode: The auth code that was sent to the user
     - parameter scopes: array of scopes you want the token to contain
     - parameter persistUser: whether the login status should be persistent on app's relaunches
     - parameter completion: the callback that is called after the auth code is checked
     */
    public func validate(oneTimeCode: String, scopes: [String] = [], persistUser: Bool, completion: @escaping NoValueCallback) {
        enum ValidateCallbackStatus {
            case success
            case failure
            case unsent
            case unavailable
        }

        let maybeEmail = try? PasswordlessTokenStore.getData(for: .email).identifier
        let maybePhone = try? PasswordlessTokenStore.getData(for: .sms).identifier

        var callbackStatuses: [ValidateCallbackStatus] = [
            maybeEmail == nil ? .unavailable : .unsent,
            maybePhone == nil ? .unavailable : .unsent,
        ]

        if callbackStatuses[0] == .unavailable && callbackStatuses[1] == .unavailable {
            struct NothingToValidate: Error {}
            completion(.failure(ClientError.unexpected(NothingToValidate())))
            return
        }

        let validateEmailCallbackStatusIndex = 0
        let validatePhoneCallbackStatusIndex = 1

        func createCallback(thisCallbackStatusIndex: Int, otherCallbackStatusIndex: Int) -> NoValueCallback {
            return { [weak self] result in
                self?.dispatchIfSelf {
                    switch result {
                    case .success:
                        // Only case we do not call completion is if the other callback succeeded already
                        callbackStatuses[thisCallbackStatusIndex] = .success
                        switch callbackStatuses[otherCallbackStatusIndex] {
                        case .success:
                            break
                        default:
                            completion(result)
                        }
                    case .failure:
                        // Only call completion if other has already failed or us unavailable
                        callbackStatuses[thisCallbackStatusIndex] = .failure
                        switch callbackStatuses[otherCallbackStatusIndex] {
                        case .failure, .unavailable:
                            completion(result)
                        default: break
                        }
                    }
                }
            }
        }

        if let email = maybeEmail {
            self.validate(oneTimeCode: oneTimeCode, for: email, scopes: scopes, persistUser: persistUser, completion: createCallback(
                thisCallbackStatusIndex: validateEmailCallbackStatusIndex,
                otherCallbackStatusIndex: validatePhoneCallbackStatusIndex
            ))
        }

        if let phone = maybePhone {
            self.validate(oneTimeCode: oneTimeCode, for: phone, scopes: scopes, persistUser: persistUser, completion: createCallback(
                thisCallbackStatusIndex: validatePhoneCallbackStatusIndex,
                otherCallbackStatusIndex: validateEmailCallbackStatusIndex
            ))
        }
    }

    /**
     Authenticate using e-mail and password.

     - parameter username: `Identifier` representing the username to login with. Only email is supported.
     - parameter password: the password for the identifier
     - parameter scopes: array of scopes you want the token to contain
     - parameter persistUser: whether the login status should be persistent on app's relaunches
     - parameter completion: a callback that is called after the credential is checked.
     */
    public func login(username: Identifier, password: String, scopes: [String] = [], persistUser: Bool, completion: @escaping NoValueCallback) {
        guard case .email = username else {
            completion(.failure(ClientError.unexpectedIdentifier(actual: username, expected: "only EmailAddress supported")))
            return
        }

        self.api.requestAccessToken(
            clientID: self.clientConfiguration.clientID,
            clientSecret: self.clientConfiguration.clientSecret,
            grantType: .password,
            refreshToken: nil,
            username: username.normalizedString,
            password: password,
            scope: (scopes + IdentityManager.defaultScopes).duplicatesRemoved()
        ) { [weak self] result in
            self?.finishLogin(result: result, persistUser: persistUser, completion: completion)
        }
    }

    /**
     Signup using e-mail and password.

     This method does not result in a valid `currentUser` object. The reason is that either the identifier
     already exists in the system, in which case you will get a `ClientError.alreadyRegistered`, or the
     identifier needs to be verified, in which case there will be an eventual deep link back in to your
     application that can be parsed with `AppLaunchData` and verified with `validate(authCode:completion:)`

     This API results in an email being sent to the user to complete the process. Once a user clicks on a verification
     email, a number of things can happen, they can be:

     1. Redirected to the app via the url scheme (see `ClientConfiguration.appURLScheme`)
     1. Redirected to a webflow to accept terms and conditions, and then redirected to the app
     1. Redirected to a webflow to update/input required fields and then redirected to the app

     ### Checking identifier before calling signup

     If you try and signup with an identifier that already exists, you will get an error. If you need to check the
     status of an identifier you should use `fetchStatus(for:completion:)` first.

     ### Terms and conditions and privacy policy

     The redirection to the webflow terms and condition screen can be bypassed if you accept terms through this API.
     However, if you do do this then you are responsible for actually showing the terms to the user. This tells us
     that the user has explicitly accepted the platform (SPiD) terms and conditions and been notified of the privacy
     policy, and also has done the same for the client's (your) terms and conditions and privacy policy.

     - SeeAlso: `fetchTerms(completion:)`

     ### Required fields

     Depending on how you've set up your client in self service, the user may also need to fill in some required fields.
     If you want to bypass the webflow for these as well, then you must provide a valid `UserProfile` object that fulfills
     all of your client's required fields.

     - SeeAlso: `requiredFields(completion:)`

     - parameter username: `Identifier` representing the username to signup
     - parameter password: password for identifier
     - parameter profile: profile information to be set on created user
     - parameter acceptTerms: this must be set to true to create a user
     - parameter redirectPath: The signup process will eventually deep link back to your app with `ClientConfiguration.redirectBaseURL` and this argument
     - parameter persistUser: whether the login status should be persistent on app's relaunches
     - parameter completion: a callback that is called in the end (with an error object in case of failures).
     */
    public func signup(
        username: Identifier,
        password: String,
        profile: UserProfile? = nil,
        acceptTerms: Bool? = nil,
        redirectPath: String? = nil,
        persistUser: Bool,
        completion: @escaping NoValueCallback
    ) {
        guard case .email = username else {
            completion(.failure(ClientError.unexpectedIdentifier(actual: username, expected: "only EmailAddress supported")))
            return
        }

        let redirectPath = redirectPath ?? ClientConfiguration.RedirectInfo.Signup.path
        self.api.fetchClientAccessToken(
            clientID: self.clientConfiguration.clientID,
            clientSecret: self.clientConfiguration.clientSecret
        ) { [weak self] result in
            log(from: self, "clientToken: \(result)")

            let clientTokenData: TokenData
            switch result {
            case let .success(data):
                clientTokenData = data
            case let .failure(error):
                self?.dispatchIfSelf {
                    completion(.failure(ClientError(error)))
                }
                return
            }

            guard let strongSelf = self else { return }

            let redirectURL = strongSelf.clientConfiguration.redirectBaseURL(withPathComponent: redirectPath, additionalQueryItems: [
                URLQueryItem(name: ClientConfiguration.RedirectInfo.persistUserKey, value: persistUser ? "true" : "false"),
            ])

            strongSelf.api.signup(
                oauthToken: clientTokenData.accessToken,
                email: username.normalizedString,
                password: password,
                redirectURI: redirectURL.absoluteString,
                profile: profile,
                acceptTerms: acceptTerms
            ) { [weak self] result in
                log(from: self, result)

                Settings.setValue(redirectPath, forKey: ClientConfiguration.RedirectInfo.Signup.settingsKey)

                switch result {
                case .success:
                    self?.dispatchIfSelf {
                        completion(.success(()))
                    }
                case let .failure(error):
                    self?.dispatchIfSelf {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    /**
     Log in by an auth code.

     The authorization code is passed into the app from SPiD after the user verified their email.

     - parameter authCode: an authorization code (currently it's just available through deeplinks)
     - parameter completion: the callback that is called after validation
     - parameter scopes: array of scopes you want the token to contain
     - parameter persistUser: whether the login status should be persistent on app's relaunches

     - SeeAlso: `AppLaunchData`
     */
    public func validate(authCode: String, persistUser: Bool, completion: @escaping NoValueCallback) {
        self.api.requestAccessToken(
            clientID: self.clientConfiguration.clientID,
            clientSecret: self.clientConfiguration.clientSecret,
            grantType: .authorizationCode,
            code: authCode,
            // this parameter is useless, but required, otherwise you get "invalid_request" error
            redirectURI: self.clientConfiguration.redirectBaseURL(withPathComponent: nil).absoluteString
        ) { [weak self] result in
            self?.finishLogin(result: result, persistUser: persistUser, completion: completion)
        }
    }

    private func finishLogin(result: Result<TokenData, ClientError>, persistUser: Bool, completion: NoValueCallback?) {
        log(from: self, result)
        do {
            let tokens = try result.materialize()
            try self.currentUser.set(
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
                idToken: tokens.idToken,
                userID: tokens.userID,
                makePersistent: persistUser
            )
            PasswordlessTokenStore.clear()
            self.dispatchIfSelf {
                completion?(.success(()))
            }
        } catch {
            self.dispatchIfSelf {
                completion?(.failure(ClientError(error)))
            }
        }
    }

    /**
     Fetch the `IdentifierStatus` for the supplied identifier

     - parameter identifier: The identifier you want the status for
     - parameter completion: contains an `IdentifierStatus` object on success
     */
    public func fetchStatus(for identifier: Identifier, completion: @escaping IdentifierStatusResultCallback) {
        self.api.fetchClientAccessToken(
            clientID: self.clientConfiguration.clientID,
            clientSecret: self.clientConfiguration.clientSecret
        ) { [weak self] result in
            log(from: self, "clientToken: \(result)")

            guard let strongSelf = self else { return }

            let clientTokenData: TokenData
            switch result {
            case let .success(data):
                clientTokenData = data
            case let .failure(error):
                self?.dispatchIfSelf {
                    completion(.failure(ClientError(error)))
                }
                return
            }

            let identifierInBase64 = Data(identifier.normalizedString.utf8)
                .base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")

            strongSelf.api.fetchIdentifierStatus(
                oauthToken: clientTokenData.accessToken,
                identifierInBase64: identifierInBase64,
                connection: identifier.connection
            ) { [weak self] result in
                log(from: self, result)

                switch result {
                case let .success(model):
                    self?.dispatchIfSelf {
                        completion(.success(model))
                    }
                case let .failure(error):
                    self?.dispatchIfSelf {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    /**
     Retrieve the latest terms & conditions links for the platform (i.e. SPiD) and client (i.e. your app).

     The platform terms returned are the default ones associated with the identity platform.
     The client terms are what are associated with your client ID and can be set in
     [SPiD selfservice](http://techdocs.spid.no/selfservice/access/) under "Assign T&C" page.

     - parameter completion: a callback that receives the `Terms` model.
     */
    public func fetchTerms(completion: @escaping TermsResultCallback) {
        self.api.fetchTerms(
            clientID: self.clientConfiguration.clientID
        ) { [weak self] result in

            log(from: self, result)

            guard self != nil else { return }

            switch result {
            case let .success(terms):
                self?.dispatchIfSelf {
                    completion(.success(terms))
                }
            case let .failure(error):
                self?.dispatchIfSelf {
                    completion(.failure(ClientError(error)))
                }
            }
        }
    }

    /**
     Fetches the list of required fields that this client expects

     The required fields can be set in [SPiD selfservice](http://techdocs.spid.no/selfservice/access/).

     - parameter completion: a callback that's called on completion and might receive an error.
     */
    public func requiredFields(completion: @escaping RequiredFieldsResultCallback) {
        self.api.fetchClientAccessToken(
            clientID: self.clientConfiguration.clientID,
            clientSecret: self.clientConfiguration.clientSecret
        ) { [weak self] result in
            log(from: self, "clientToken: \(result)")

            guard let strongSelf = self else { return }

            let clientTokenData: TokenData
            switch result {
            case let .success(data):
                clientTokenData = data
            case let .failure(error):
                self?.dispatchIfSelf {
                    completion(.failure(ClientError(error)))
                }
                return
            }

            strongSelf.api.fetchClient(
                oauthToken: clientTokenData.accessToken,
                clientID: strongSelf.clientConfiguration.clientID
            ) { [weak self] result in
                log(from: self, result)

                switch result {
                case let .success(model):
                    self?.dispatchIfSelf {
                        completion(.success(model.requiredFields))
                    }
                case let .failure(error):
                    self?.dispatchIfSelf {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    /**
     Retrieve information from self serivice about your app

     Some information from spid that is associated with your client ID and can be set in
     [SPiD selfservice](http://techdocs.spid.no/selfservice/access/)

     - parameter completion: a callback that receives the `Client` model.
     */
    public func fetchClient(completion: @escaping ClientResultCallback) {
        self.api.fetchClientAccessToken(
            clientID: self.clientConfiguration.clientID,
            clientSecret: self.clientConfiguration.clientSecret
        ) { [weak self] result in
            log(from: self, "clientToken: \(result)")

            let clientTokenData: TokenData
            switch result {
            case let .success(data):
                clientTokenData = data
            case let .failure(error):
                self?.dispatchIfSelf {
                    completion(.failure(ClientError(error)))
                }
                return
            }

            guard let strongSelf = self else { return }

            strongSelf.api.fetchClient(
                oauthToken: clientTokenData.accessToken,
                clientID: strongSelf.clientConfiguration.clientID
            ) { [weak self] result in

                log(from: self, result)

                switch result {
                case let .success(terms):
                    self?.dispatchIfSelf {
                        completion(.success(terms))
                    }
                case let .failure(error):
                    self?.dispatchIfSelf {
                        completion(.failure(ClientError(error)))
                    }
                }
            }
        }
    }
}

extension IdentityManager: UserDelegate {
    public func user(_: User, didChangeStateTo newState: UserState) {
        guard self.delegate != nil else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            log(from: self, "delegating state: \(newState)")
            self?.delegate?.userStateChanged(newState)
        }
    }
}
