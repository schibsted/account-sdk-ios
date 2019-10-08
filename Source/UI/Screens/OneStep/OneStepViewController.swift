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

    @IBOutlet var rememberMe: NormalLabel! {
        didSet {
            self.rememberMe.text = self.viewModel.persistentLogin
        }
    }

    @IBOutlet var whatsThisButton: UIButton! {
        didSet {
            self.whatsThisButton.setTitle(self.viewModel.whatsThis, for: .normal)
            self.whatsThisButton.titleLabel?.font = self.theme.fonts.info
            self.whatsThisButton.contentEdgeInsets.top = 1
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

    @IBOutlet var continueButton: PrimaryButton!  {
        didSet {
            self.continueButton.setTitle(self.viewModel.proceed, for: .normal)
        }
    }

    // TODO fix UI for teaser (missing logos?)
    @IBOutlet var teaser: NormalLabel! {
        didSet {
            self.teaser.text = self.viewModel.localizedTeaserText
        }
    }

    private let viewModel: OneStepViewModel

    init(configuration: IdentityUIConfiguration, navigationSettings: NavigationSettings, viewModel: OneStepViewModel) {
        self.viewModel = viewModel
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

    override func startLoading() {
        super.startLoading()
        self.inputError.isHidden = true
        self.password.applyUnfocusedStyle()
        self.continueButton.isAnimating = true
    }

    override func endLoading() {
        super.endLoading()
        self.continueButton.isAnimating = false
    }

    @discardableResult override func showInlineError(_ error: ClientError) -> Bool {
        let message: String
        switch error {
        case .invalidUserCredentials:
            message = self.viewModel.invalidPassword
        default:
            return false
        }

        self.configuration.tracker?.error(.validation(error), in: self.trackerScreenID)

        self.inputError.text = message
        self.inputError.isHidden = false
        self.password.layer.borderColor = self.theme.colors.errorBorder.cgColor

        return true
    }
    @IBOutlet var inputError: ErrorLabel! {
        didSet {
            self.inputError.isHidden = true
        }
    }
}
