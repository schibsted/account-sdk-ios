//
//  OneStepViewController.swift
//  SchibstedAccount
//

import UIKit

class OneStepViewController: IdentityUIViewController {
    enum Action {
        case enter(identifier: Identifier, password: String, shouldPersistUser: Bool)
    }

    var didRequestAction: ((Action) -> Void)?

    @IBOutlet var emailAddress: TextField! {
        didSet {
            self.emailAddress.keyboardType = .emailAddress
            self.emailAddress.autocorrectionType = .no
            self.emailAddress.clearButtonMode = .whileEditing
//            self.emailAddress.delegate = self // TODO
            if #available(iOS 11.0, *) {
                self.emailAddress.textContentType = .username
            }
        }
    }

    @IBOutlet var password: TextField! {
        didSet {
            self.password.keyboardType = .default
            self.password.autocorrectionType = .no
            //            self.emailAddress.delegate = self // TODO
            self.password.clearButtonMode = .whileEditing
            self.password.isSecureTextEntry = true

            if #available(iOS 11.0, *) {
                self.password.textContentType = .password
            }
        }
    }

    @IBOutlet var shouldPersistUserCheck: Checkbox! {
        didSet {
            self.shouldPersistUserCheck.isChecked = true
        }
    }

    init(configuration: IdentityUIConfiguration, navigationSettings: NavigationSettings, viewModel: OneStepViewModel) {
        super.init(
            configuration: configuration,
            navigationSettings: navigationSettings,
            trackerScreenID: .oneStepForm,
            trackerViewAdditionalFields: [.teaser(viewModel.localizedTeaserText != nil)]
        )
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func didClickContinue(_: Any) {
        self.configuration.tracker?.interaction(.submit, with: self.trackerScreenID, additionalFields: [.keepLoggedIn(self.shouldPersistUserCheck.isChecked)])

        let identifier: Identifier
        guard let text = self.emailAddress.text?.trimmingCharacters(in: .whitespaces) else {
            return
        }
        guard let email = EmailAddress(text) else {
            self.showInlineError(.invalidEmail)
            return
        }
        identifier = Identifier(email)

        guard let password = self.password.text else {
            return
        }

        self.didRequestAction?(.enter(identifier: identifier, password: password, shouldPersistUser: self.shouldPersistUserCheck.isChecked))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO get raw string from viewModel
        let toolbar = UIToolbar.forKeyboard(target: self, doneString: "Done", doneSelector: #selector(self.didClickContinue))

        self.password.inputAccessoryView = toolbar
    }
}
