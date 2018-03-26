//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import SchibstedAccount
import UIKit

class TokenExchangeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func requestCodeForAPIAuthorization(_: UIButton) {
        UIApplication.identityManager.currentUser.auth.oneTimeCode(clientID: UIApplication.identityManager.clientConfiguration.clientID) { result in
            switch result {
            case let .success(code):
                print("requestCodeForAPIAuthorization code: \(code)")
            case let .failure(error):
                print("requestCodeForAPIAuthorization error: \(error)")
            }
        }
    }

    @IBAction func loadWebView(_: Any) {
        // The client ID here must match the web client ID of the example site.
        // And the client config used to launch the app must be the .sdkExample config
        guard let clientID = UIApplication.identityManager.clientConfiguration.webClientID,
            let redirectURL = UIApplication.identityManager.clientConfiguration.sdkExampleRedirectURL
        else {
            print("client config does not support a web view")
            return
        }

        UIApplication.identityManager.currentUser.auth.webSessionURL(
            clientID: clientID,
            redirectURL: redirectURL
        ) { result in
            if case let .success(url) = result {
                UIApplication.shared.openURL(url)
            }
        }
    }
    @IBAction func requestCodeForWebSessionInit(_: UIButton) {
        // likely to set a path and/or query here
        //let redirectURL = URL(string: "/...", relativeTo: identityManager.configuration.redirectBaseURL)!
        let redirectURL = UIApplication.identityManager.clientConfiguration.redirectBaseURL(withPathComponent: nil)
        UIApplication.identityManager.currentUser.auth.webSessionURL(
            clientID: UIApplication.identityManager.clientConfiguration.clientID,
            redirectURL: redirectURL
        ) { result in
            switch result {
            case let .success(url):
                print("requestCodeForWebSessionInit url: \(url)")
            case let .failure(error):
                print("requestCodeForWebSessionInit error: \(error)")
            }
        }
    }
}
