//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 The user object is the central part of the SDK. Once one is created, it is recommended to hold on
 to it until you do not need it anymore.

 There are 2 ways to create a valid user object currently:
 1. Through the `IdentityManager`
 1. Through the `IdentityUI`

 It is recommended that you create one using the provided UI flows. But if the need arises the headless
 approach is also documented, but not "officially" supported.

 ### Checking if you have an already logged in user

 The process to check that is currently supported by the `IdentityManager.currentUser` object. Once an
 identity manager is initialized, it's internal user object is either in a logged in state or not.

 Based on the state of `IdentityManager.currentUser`, you may either proceed to get one or store it and
 use it for whatever else.

 In order to comply with privacy regulations, you need to make sure that the user accepts any update
 to terms and conditions that may have been issued since the last visit. For this reason, at the
 startup of your app, right after having obtained the `IdentityManager.currentUser` and verified the
 login status, if the user is logged-in you should call `user.agreements.status(:)` and, in case of
 `false` result (meaning the user has yet to accepted the latest terms), obtain the latest terms by
 calling `IdentityManager.fetchTerms(:) and finally present a screen where the user can review and accept
 the updated terms. The recommended way of presenting the screen is by using the provided UI flows, thus
 by calling `IdentityUI.presentTerms(for:from:)`.

 If you are using the headless approach instead, you should then present your own UI and manually
 call `user.agreements.accept(:)`, if the user accepted the new terms, or `logout()`, if the user
 rejected them.
 */
public class User: UserProtocol {
    static var globalStore = SynchronizedWeakDictionary<Int, User>()

    enum Failure: Error {
        case missingToken(String?, String?)
        case missingUserID
    }

    /// Provides auth-related APIs
    public internal(set) var auth: UserAuthAPI

    /// Provides access to this user's profile data
    public internal(set) var profile: UserProfileAPI

    /// Provides access to the state of this user's terms acceptance
    public internal(set) var agreements: UserAgreementsAPI

    /// Provides access to product information for this user
    /// Note: This is a privileged API and access must be requested through support@spid.no for your specific client.
    public internal(set) var product: UserProductAPI

    ///
    public weak var delegate: UserDelegate?

    var willDeinit = EventEmitter<()>(description: "User.willDeinit")

    let api: IdentityAPI
    let clientConfiguration: ClientConfiguration

    var taskManager: TaskManager!

    private let dispatchQueue = DispatchQueue(label: "com.schibsted.identity.User", attributes: [])
    private var _tokens: TokenData?
    private var isPersistent = false

    var tokens: TokenData? {
        return self.dispatchQueue.sync {
            self._tokens
        }
    }

    /**
     A user_id used by some SPID APIs

     It is recommended to use `id` instead of this.
     */
    public var legacyID: String? {
        return self.tokens?.userID
    }

    /**
     Returns the user id for your client, if valid
     */
    public var id: String? {
        return self.tokens?.anyUserID
    }

    /**
     Returns current state of User object
     */
    public var state: UserState {
        return self.tokens == nil ? .loggedOut : .loggedIn
    }

    /**
     Initialized a user object

     Even though you can initialize a user object with a client configuration, unless you are communicating with your
     own test servers where authentication is bypassed, none of the APIs will really work. This user must be created
     via the `IdentityUI` or the `IdentityManager` to be complete.

     Else one is just another lost soul in the endless sea of digital bits.
     */
    public init(clientConfiguration: ClientConfiguration) {
        self.clientConfiguration = clientConfiguration
        self.api = IdentityAPI(basePath: clientConfiguration.serverURL)
        let userAuth = User.Auth()
        let userAgreements = User.Agreements()
        let userProfile = User.Profile()
        let userProduct = User.Product()
        self.auth = userAuth
        self.agreements = userAgreements
        self.profile = userProfile
        self.product = userProduct
        userAuth.user = self
        userAgreements.user = self
        userProfile.user = self
        userProduct.user = self
        self.taskManager = TaskManager(for: self)
        User.globalStore[ObjectIdentifier(self).hashValue] = self
        log(from: self, "added User \(ObjectIdentifier(self).hashValue) to global store")
    }

    deinit {
        self.willDeinit.emitSync(())
        User.globalStore[ObjectIdentifier(self).hashValue] = nil
        log(from: self, "removed User \(ObjectIdentifier(self).hashValue) from global store")
    }

    /**
     Logs a user out. Ie: Makes it invalid

     If the user is already logged out nothing will happen. If not then the delegate will be informed of a state change.
     */
    public func logout() {
        log(from: self, "state = \(self.state)")
        var maybeOldTokens: TokenData?
        self.dispatchQueue.sync {
            if self._tokens == nil {
                return
            }
            maybeOldTokens = self._tokens
            self._tokens = nil
        }

        guard let oldTokens = maybeOldTokens else {
            return
        }

        try? UserTokensStorage().clear(oldTokens)
        self.delegate?.user(self, didChangeStateTo: .loggedOut)

        self.api.logout(oauthToken: oldTokens.accessToken) { [weak self] result in
            log(from: self, "logging out - server session result: \(result)")
        }
    }

    func set(
        accessToken newAccessToken: String? = nil,
        refreshToken newRefreshToken: String? = nil,
        idToken newIDToken: IDToken? = nil,
        userID newUserID: String? = nil,
        makePersistent: Bool? = nil
    ) throws {
        //
        // This sync block makes sure that the only way new tokens are set on this user object is if we have both an
        // access token and a refresh token, and either an idToken or a userID
        //
        // If anything is missing as an argument, the function checks if they were set before and then just assumes
        // you're changing one or more tokens but don't need to change all of them
        //
        let tokens = try self.dispatchQueue.sync { () -> (new: TokenData?, old: TokenData?) in
            let maybeAccessToken = newAccessToken ?? self._tokens?.accessToken
            let maybeRefreshToken = newRefreshToken ?? self._tokens?.refreshToken

            guard let accessToken = maybeAccessToken, let refreshToken = maybeRefreshToken else {
                throw Failure.missingToken(maybeAccessToken?.gut(), maybeRefreshToken?.gut())
            }

            let maybeIDToken: IDToken?
            let maybeLegacyUserID: String?
            // id token and user id must be set as pairs always, so that they are always correlated
            if newUserID != nil || newIDToken != nil {
                maybeIDToken = newIDToken
                maybeLegacyUserID = newUserID
            } else {
                maybeIDToken = self._tokens?.idToken
                maybeLegacyUserID = self._tokens?.userID
            }

            guard maybeLegacyUserID != nil || maybeIDToken != nil else {
                throw Failure.missingUserID
            }

            let newTokens = TokenData(
                accessToken: accessToken,
                refreshToken: refreshToken,
                idToken: maybeIDToken,
                userID: maybeLegacyUserID
            )

            guard self._tokens != newTokens else {
                return (new: nil, old: self._tokens)
            }

            let maybeOldTokens = self._tokens
            self._tokens = newTokens
            return (new: newTokens, old: maybeOldTokens)
        }

        guard let newTokens = tokens.new else {
            // noop if no new tokens set
            log(from: self, "no new tokens to set")
            return
        }

        log(from: self, "new tokens \(newTokens)")

        self.isPersistent = makePersistent ?? self.isPersistent

        let isNewLoggedInUser = newTokens.anyUserID != nil && newTokens.anyUserID != tokens.old?.anyUserID

        if self.isPersistent {
            // Store new tokens if we are supposed to be persistent.
            // Only clear previous tokens if the user is NOT a new one (since they have not logged out)
            if let newTokens = tokens.new {
                try? UserTokensStorage().store(newTokens)
            }
            if !isNewLoggedInUser, let oldTokens = tokens.old {
                try UserTokensStorage().clear(oldTokens)
            }
        }

        if isNewLoggedInUser {
            self.delegate?.user(self, didChangeStateTo: .loggedIn)
        }
    }

    func loadStoredTokens() throws {
        let tokens = try UserTokensStorage().loadTokens()
        try self.set(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            idToken: tokens.idToken,
            userID: tokens.userID
        )

        // Since credentials were already saved, we assume login is persistent.
        self.isPersistent = true
    }

    func persistCurrentTokens() {
        guard !self.isPersistent, let tokens = self.tokens else { return }
        do {
            try UserTokensStorage().store(tokens)
            self.isPersistent = true
        } catch {
            log(from: self, "failed to persist tokens: \(error)")
        }
    }

    func refresh(completion: @escaping NoValueCallback) {
        guard let tokens = self.tokens else {
            completion(.failure(.invalidUser))
            return
        }

        guard let refreshToken = tokens.refreshToken else {
            log(from: self, "no refresh token", force: true)
            completion(.failure(.userRefreshFailed(GenericError.Unexpected("no refresh token for user \(self)"))))
            return
        }

        log(from: self, "refreshing with \(refreshToken.gut())")

        self.api.requestAccessToken(
            clientID: self.clientConfiguration.clientID,
            clientSecret: self.clientConfiguration.clientSecret,
            grantType: .refreshToken,
            refreshToken: tokens.refreshToken
        ) { [weak self] result in

            log(from: self, "refresh result on token \(refreshToken.gut()): \(result)")

            guard let strongSelf = self else {
                completion(.failure(.invalidUser))
                return
            }

            switch result {
            case let .success(model):
                if let refreshToken = model.refreshToken {
                    do {
                        try strongSelf.set(accessToken: model.accessToken, refreshToken: refreshToken)
                        completion(.success(()))
                    } catch {
                        completion(.failure(.unexpected(error)))
                    }
                } else {
                    // TODO: hacky, not really a json error. More because of the way swagger spec is. This property
                    // is "optional" in the swagger spec because it can't the end point is the same for other backend
                    // functionality that doesn't return a refresh_token. This should ideally originate from inside
                    // the API call where the JSON is actually being parsed.
                    completion(.failure(.unexpected(JSONError.noKey("refreshToken"))))
                }
            case let .failure(error):
                completion(.failure(ClientError(error)))
            }
        }
    }
}

extension User: CustomStringConvertible {
    public var description: String {
        return "<id:\(self.id?.gut() ?? "")>"
    }
}

extension User: Equatable {
    /**
     Compare User objects by "id".
     */
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

func == (lhs: TokenData, rhs: TokenData) -> Bool {
    return lhs.accessToken == rhs.accessToken
        && lhs.idToken == rhs.idToken
        && lhs.refreshToken == rhs.refreshToken
        && lhs.userID == rhs.userID
}

extension User.Failure: CustomStringConvertible {
    var description: String {
        switch self {
        case let .missingToken(accessToken, refreshToken):
            let a: String? = accessToken == nil ? "accessToken" : nil
            let r: String? = refreshToken == nil ? "refreshToken" : nil
            let tokens = [a, r].filter { return $0 != nil }.map { $0! }
            return "Did not find all expected tokens. Missing - \(tokens.joined(separator: ","))"
        case .missingUserID:
            return "IDToken and userID missing. One required"
        }
    }
}

extension User.Failure: ClientErrorConvertible {
    var clientError: ClientError {
        return .unexpected(self)
    }
}
