//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import SchibstedAccount
import UIKit

class PasswordFlowViewController: UIViewController {
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var shouldPersistUserSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    var email: EmailAddress? {
        guard let text = emailField.text else { return nil }
        return EmailAddress(text)
    }

    var password: String? {
        guard let text = passwordField.text else { return nil }
        return text
    }

    @IBAction func login(_: UIButton) {
        guard let email = self.email, let password = self.password else { return }
        UIApplication.identityManager.login(email: email, password: password, scopes: ClientConfiguration.current.scopes, persistUser: shouldPersistUserSwitch.isOn) { result in
            print(result)
        }
    }

    @IBAction func signup(_: UIButton) {
        guard let email = self.email, let password = self.password else { return }
        UIApplication.identityManager.signup(email: email, password: password, persistUser: shouldPersistUserSwitch.isOn) { result in
            print(result)
        }
    }

    func validateDeepLinkCode(_ code: String, persistUser: Bool, codeVerifier: String? = nil) {
        UIApplication.identityManager.validate(authCode: code, persistUser: persistUser, codeVerifier: codeVerifier) { result in
            switch result {
            case .success:
                print("Code validated!")
            case let .failure(error):
                print(error)
            }
        }
    }

    @IBAction func checkIfVerified(_: UIButton) {
        guard let email = self.email else { return }
        UIApplication.identityManager.fetchStatus(for: Identifier(email)) { result in
            switch result {
            case let .success(value):
                print("\(email) is verified: \(value)")
            case let .failure(error):
                print(error)
            }
        }
    }

    @IBAction func canSignup(_: UIButton) {
        guard let email = self.email else { return }
        UIApplication.identityManager.fetchStatus(for: Identifier(email)) { result in
            switch result {
            case let .success(value):
                print("\(email) is available for signup: \(value)")
            case let .failure(error):
                print(error)
            }
        }
    }
}
