//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

@testable import SchibstedAccount
import UIKit

extension StatusViewController: UserDelegate {
    func user(_ user: User, didChangeStateTo state: UserState) {
        print("UserDelegate: user \(user) changed state to \(state)")
        switch state {
        case .loggedIn:
            // This can only happen with headless login because a visual login results in IdentityUIDelegate.didFinish and uses it's own internal IdentityManager
            //
            // For a headless login we first catch the first time we log in with the IdentityManager and then we hijack it's internal currentUser and set our own
            // delegate. So when we login again with the IdentityManager, we get to this point
            DispatchQueue.main.async { [weak self] in
                UIApplication.currentUser = UIApplication.identityManager.currentUser
                UIApplication.currentUser.delegate = self
            }
        case .loggedOut:
            break
        }
        DispatchQueue.main.async { [weak self] in
            self?.updateFromCurrentUser()
        }
    }
}

extension StatusViewController: IdentityManagerDelegate {
    func userStateChanged(_ state: UserState) {
        print("IdentityManagerDelegate: user \(UIApplication.identityManager.currentUser) changed state to \(state)")
        // Hijack internal IdentityManager user and set our own delegate
        UIApplication.currentUser = UIApplication.identityManager.currentUser
        UIApplication.currentUser.delegate = self
        self.updateFromCurrentUser()
    }
}

extension StatusViewController: IdentityUIDelegate {
    func didFinish(result: IdentityUIResult) {
        print("IdentityUIDelegate: result \(result)")
        switch result {
        case let .completed(user):
            UIApplication.currentUser = user
            UIApplication.currentUser.delegate = self
            DispatchQueue.main.async { [weak self] in
                self?.updateFromCurrentUser()
            }
        case .canceled, .skipped, .failed:
            break
        }
    }

    func willPresent(flow: LoginMethod.FlowVariant) -> LoginFlowDisposition {
        if self.loginOnlySwitch.isOn && flow == .signup {
            return .showError(
                title: "Custom error",
                description: "It's my desc and I'll do what I want"
            )
        } else {
            return .continue
        }
    }

    func skipRequested(topViewController: UIViewController, done: @escaping (SkipLoginDisposition) -> Void) {
        let alert = UIAlertController(title: "Are you sure?", message: "Skipping the flow will place a curse on your socks", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes, skip it", style: .default) { _ in
            done(.continue)
        })
        alert.addAction(UIAlertAction(title: "No don't!!", style: .cancel) { _ in
            done(.ignore)
        })
        topViewController.present(alert, animated: true, completion: nil)
    }

    func willSucceed(with user: User, on topViewController: UIViewController?, done: @escaping (LoginWillSucceedDisposition) -> Void) {
        print("Gonna succeed with user - \(user)")
        let alert = UIAlertController(title: "About to login", message: "Should I continue, restart flow, or fail with some message?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            done(.continue)
        })
        alert.addAction(UIAlertAction(title: "Restart", style: .destructive) { _ in
            done(.restart)
        })
        alert.addAction(UIAlertAction(title: "Fail", style: .cancel) { _ in
            done(.failed(title: "Some message", message: "This login attempt has failed"))
        })
        if let topViewController = topViewController {
            topViewController.present(alert, animated: true, completion: nil)
        } else {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

class StatusViewController: UIViewController {
    var session: URLSession?

    @IBOutlet var userStateLabel: UILabel!
    @IBOutlet var userIDLabel: UILabel!
    @IBOutlet var offlineModeSwitch: UISwitch!
    @IBOutlet var loginOnlySwitch: UISwitch!

    @IBAction func offlineModeValueChanged(_: UISwitch) {
        UIApplication.offlineMode = self.offlineModeSwitch.isOn
    }

    @IBAction func didClickPasswordlessEmailLogin(_: Any) {
        UIApplication.identityUI.presentIdentityProcess(from: self, loginMethod: .email)
    }

    @IBAction func didClickPasswordlessPhoneLogin(_: Any) {
        UIApplication.identityUI.presentIdentityProcess(from: self, loginMethod: .phone, scopes: ClientConfiguration.current.scopes)
    }

    @IBAction func didClickPasswordLogin(_: Any) {
        UIApplication.identityUI.presentIdentityProcess(
            from: self,
            loginMethod: .password,
            localizedTeaserText: "I'm a teaser, I'm a teaser, I'm a teaser, I'm a teaser, I'm a teaser, I'm a teaser",
            scopes: ClientConfiguration.current.scopes
        )
    }

    @IBAction func didClickOpenProfile(_: Any) {
        let accountURL = UIApplication.identityManager.routes.accountSummaryURL

        let alert = UIAlertController(title: "Mood", message: "Would you like to go through SPiD or the BFF?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "SPiD", style: .default) { _ in
            UIApplication.shared.openURL(accountURL)
        })
        alert.addAction(UIAlertAction(title: "BFF", style: .default) { _ in
            guard var components = URLComponents(url: ClientConfiguration.current.serverURL, resolvingAgainstBaseURL: true) else {
                print("could not create URLCOmponents from \(ClientConfiguration.current.serverURL)")
                return
            }
            var queryItems: [URLQueryItem] = []
            // This must be a web client ID
            queryItems.append(URLQueryItem(name: "client_id", value: ClientConfiguration.current.webClientID))
            queryItems.append(URLQueryItem(name: "response_type", value: "code"))
            queryItems.append(URLQueryItem(name: "new-flow", value: "true"))
            // This must be added to the allowed redirects of the web client ID
            queryItems.append(URLQueryItem(name: "redirect_uri", value: accountURL.absoluteString))
            queryItems.append(URLQueryItem(name: "scope", value: "openid"))
            queryItems.append(URLQueryItem(name: "state", value: "someting"))
            components.path = "/oauth/authorize"
            components.queryItems = queryItems

            guard let url = components.url else {
                print("could not create url from \(components)")
                return
            }
            UIApplication.shared.openURL(url)
        })

        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func didClickScopes(_: Any) {
        var message: String = "n/a"
        if let scopes = UIApplication.currentUser.tokens?.accessToken {
            if let jwt = try? JWTHelper.toJSON(string: scopes) {
                do {
                    message = try jwt.string(for: "scope").replacingOccurrences(of: " ", with: "\n")
                } catch {
                    message = "\(error)"
                }
            }
        }
        let alert = UIAlertController(title: "Scopes", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func didClickRefresh(_: Any) {
        UIApplication.currentUser.refresh { result in
            switch result {
            case .success:
                print("refresh succeeded")
            case let .failure(error):
                print(error)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.identityUI.delegate = self
        UIApplication.currentUser.delegate = self
        UIApplication.identityManager.delegate = self

        self.updateFromCurrentUser()
    }

    var isUserLoggedIn: Bool {
        return UIApplication.currentUser.state == .loggedIn
    }

    func updateFromCurrentUser() {
        self.userStateLabel.text = self.isUserLoggedIn ? "yes" : "no"
        self.userIDLabel.text = String(describing: UIApplication.currentUser)
        self.session = URLSession(user: UIApplication.currentUser, configuration: URLSessionConfiguration.default)
    }

    @IBAction func logOut(_: UIButton) {
        UIApplication.currentUser.logout()
    }

    @IBAction func didTapReadProfileButton(_: UIButton) {
        UIApplication.currentUser.profile.fetch { result in
            switch result {
            case let .success(profile):
                print("profile.fetch: \(profile)")
                let alertController = UIAlertController(title: "Profile", message: profile.description, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alertController, animated: true, completion: nil)
            case let .failure(error):
                print("profile.fetch error: \(error)")
            }
        }
    }
}
