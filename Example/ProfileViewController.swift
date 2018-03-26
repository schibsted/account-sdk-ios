//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import SchibstedAccount
import UIKit

class ProfileViewController: UIViewController {
    @IBOutlet var givenNameTextField: UITextField!
    @IBOutlet var familyNameTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func didTapSubmitButton(_: UIButton) {
        guard let givenName = givenNameTextField.text else { return }
        guard let familyName = familyNameTextField.text else { return }
        let profile = UserProfile(givenName: givenName, familyName: familyName)

        UIApplication.identityManager.currentUser.profile.update(profile) { result in
            switch result {
            case .success:
                print("profile.update success!")
            case let .failure(error):
                print("profile.update error: \(error)")
            }
        }
    }
}
