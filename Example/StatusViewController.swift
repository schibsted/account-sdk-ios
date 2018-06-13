//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

@testable import SchibstedAccount
import UIKit

extension StatusViewController: IdentityManagerDelegate {
    // IdentityManagerDelegate
    func userStateChanged(_: UserState) {
        print("Login state changed to: \(self.isUserLoggedIn)")
        self.updateFromCurrentUser()

        // TODO: make a more sane separate test

        let task: URLSessionDataTask? = self.session?.dataTask(with: URL(string: "http://localhost:8888")!) { _, _, _ in print("Done!") }
        task?.resume()
    }
}

extension StatusViewController: IdentityUIDelegate {
    func didFinish(result: IdentityUIResult) {
        switch result {
        case .canceled:
            print("The user canceled the login process")
        case let .completed(user):
            self.session = URLSession(user: user, configuration: URLSessionConfiguration.default)
            print("User logged in - \(user)")
        case let .failed(error):
            print("Failed to login with UI - \(error)")
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
        if let scopes = UIApplication.identityManager.currentUser.tokens?.accessToken {
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
        UIApplication.identityManager.currentUser.refresh { result in
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

        UIApplication.identityManager.delegate = self
        UIApplication.identityUI.delegate = self

        self.updateFromCurrentUser()
    }

    var isUserLoggedIn: Bool {
        return UIApplication.identityManager.currentUser.state == .loggedIn
    }

    func updateFromCurrentUser() {
        self.userStateLabel.text = self.isUserLoggedIn ? "yes" : "no"
        self.userIDLabel.text = String(describing: UIApplication.identityManager.currentUser)
        self.session = URLSession(user: UIApplication.identityManager.currentUser, configuration: URLSessionConfiguration.default)
    }

    @IBAction func logOut(_: UIButton) {
        UIApplication.identityManager.currentUser.logout()
    }

    @IBAction func didTapReadProfileButton(_: UIButton) {
        UIApplication.identityManager.currentUser.profile.fetch { result in
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
