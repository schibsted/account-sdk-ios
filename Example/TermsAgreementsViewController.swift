//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import SchibstedAccount
import UIKit

class TermsAgreementsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func fetchAgreementsAcceptanceStatus(_: UIButton) {
        UIApplication.identityManager.currentUser.agreements.status { result in
            switch result {
            case let .success(isAccepted):
                print("fetchAgreementsAcceptanceStatus: \(isAccepted)")
            case let .failure(error):
                print("fetchAgreementsAcceptanceStatus error: \(error)")
            }
        }
    }

    @IBAction func acceptAgreements(_: UIButton) {
        UIApplication.identityManager.currentUser.agreements.accept { result in
            print("acceptAgreements result: \(result)")
        }
    }

    @IBAction func fetchAgreementsText(_: UIButton) {
        UIApplication.identityManager.fetchTerms { result in
            switch result {
            case let .success(links):
                print("fetchTerms: \(links)")
            case let .failure(error):
                print("fetchTerms error: \(error)")
            }
        }
    }
}
