//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class PasswordViewController: IdentityUIViewController {
    enum Action {
        case enter(password: String, shouldPersistUser: Bool)
        case changeIdentifier
        case forgotPassword
        case back
        case cancel
        case info(title: String, text: String)
    }

    @IBOutlet var whatsThisButton: UIButton! {
        didSet {
            self.whatsThisButton.setTitle(self.viewModel.whatsThis, for: .normal)
            self.whatsThisButton.titleLabel?.font = self.theme.fonts.info
            self.whatsThisButton.contentEdgeInsets.top = 1
        }
    }
    @IBAction func didClickWhatLink(_: Any) {
        self.configuration.tracker?.engagement(.click(on: .learnMoreAboutSchibsted), in: self.trackerScreenID)
        self.didRequestAction?(.info(
            title: self.viewModel.persistentLogin,
            text: self.viewModel.rememberMe
        ))
    }

    var didRequestAction: ((Action) -> Void)?

    @IBOutlet var shouldPersistUserCheck: Checkbox! {
        didSet {
            self.shouldPersistUserCheck.isChecked = true
        }
    }
    @IBOutlet var shouldPersistUserText: NormalLabel! {
        didSet {
            self.shouldPersistUserText.text = self.viewModel.persistentLogin
        }
    }
    @IBOutlet var forgotPasswordButton: SecondaryButton! {
        didSet {
            self.forgotPasswordButton.setTitle(self.viewModel.forgotPassword, for: .normal)
            self.forgotPasswordButton.isHidden = true
        }
    }
    @IBOutlet var infoLabelHeight: NSLayoutConstraint! {
        didSet {
            self.infoLabelHeight.constant = 0
        }
    }
    @IBOutlet var changeIdentifierButton: UIButton! {
        didSet {
            let image = UIImage(cgImage: self.theme.icons.chevronLeft.cgImage!, scale: self.theme.icons.chevronLeft.scale, orientation: .rightMirrored)
            self.changeIdentifierButton.setImage(image, for: .normal)
            self.changeIdentifierButton.addTarget(self, action: #selector(self.changeIdentifier), for: .touchUpInside)
        }
    }

    @IBAction func didClickForgotPassword(_: Any) {
        self.configuration.tracker?.engagement(.click(on: .forgotPassword), in: self.trackerScreenID)
        self.didRequestAction?(.forgotPassword)
    }

    @IBOutlet var ageLabel: InfoLabel! {
        didSet {
            self.ageLabel.text = self.viewModel.ageLimit
            self.ageLabel.isHidden = true
        }
    }
    @IBOutlet var infoLabel: InfoLabel! {
        didSet {
            self.infoLabel.text = self.viewModel.info
            self.infoLabel.isHidden = true
        }
    }
    @IBOutlet var identifierLabel: NormalLabel! {
        didSet {
            self.identifierLabel.text = self.viewModel.identifier.originalString
        }
    }
    @objc func changeIdentifier() {
        let prefereblyActionSheet = UIAlertController(title: self.viewModel.identifier.originalString, message: nil, preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: self.viewModel.cancel, style: .cancel, handler: nil)
        let changeAction = UIAlertAction(title: self.viewModel.change, style: .default) { [weak self] _ in
            self?.didRequestAction?(.changeIdentifier)
        }

        prefereblyActionSheet.addAction(cancelAction)
        prefereblyActionSheet.addAction(changeAction)

        if let popoverController = prefereblyActionSheet.popoverPresentationController {
            popoverController.sourceView = changeIdentifierButton
            popoverController.sourceRect = CGRect(x: self.changeIdentifierButton.bounds.minX, y: self.changeIdentifierButton.bounds.maxY, width: 0, height: 0)
            popoverController.permittedArrowDirections = [.right]
        }

        self.present(prefereblyActionSheet, animated: true, completion: nil)
    }

    @IBOutlet var password: TextField! {
        didSet {
            self.password.keyboardType = .default
            self.password.autocorrectionType = .no
            self.password.delegate = self
            self.password.clearButtonMode = .whileEditing
            self.password.isSecureTextEntry = true
        }
    }
    @IBOutlet var inputTitle: NormalLabel! {
        didSet {
            self.inputTitle.text = self.viewModel.inputTitle
        }
    }
    @IBOutlet var continueButton: PrimaryButton! {
        didSet {
            self.continueButton.setTitle(self.viewModel.proceed, for: .normal)
        }
    }
    @IBOutlet var inputError: ErrorLabel! {
        didSet {
            self.inputError.isHidden = true
        }
    }

    let viewModel: PasswordViewModel

    init(configuration: IdentityUIConfiguration, navigationSettings: NavigationSettings, viewModel: PasswordViewModel) {
        self.viewModel = viewModel
        super.init(configuration: configuration, navigationSettings: navigationSettings, trackerScreenID: .passwordInput)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let toolbar = UIToolbar.forKeyboard(target: self, doneString: self.viewModel.done, doneSelector: #selector(self.didClickContinue))

        self.password.inputAccessoryView = toolbar
        self.viewToEnsureVisibilityOfAfterKeyboardAppearance = self.password

        switch self.viewModel.loginFlowVariant {
        case .signup:
            self.infoLabel.isHidden = false
            self.infoLabelHeight.constant = 200 // (less than or equal of some big value).
            self.forgotPasswordButton.isHidden = true
            self.ageLabel.isHidden = false
        case .signin:
            self.infoLabel.isHidden = true
            self.infoLabelHeight.constant = 0
            self.forgotPasswordButton.isHidden = false
        }
    }

    @IBAction func didClickContinue(_: Any) {
        self.configuration.tracker?.interaction(.submit, with: self.trackerScreenID, additionalFields: [.keepLoggedIn(self.shouldPersistUserCheck.isChecked)])
        guard let password = self.password.text, ((self.viewModel.loginFlowVariant == .signin && password.count >= 1) || password.count >= 8) else {
            self.showInlineError(.invalidUserCredentials(message: nil))
            return
        }

        self.didRequestAction?(.enter(password: password, shouldPersistUser: self.shouldPersistUserCheck.isChecked))
    }

    override var navigationTitle: String {
        switch self.viewModel.loginFlowVariant {
        case .signup: return self.viewModel.titleSignup
        case .signin: return self.viewModel.titleSignin
        }
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
}

extension PasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.didClickContinue(textField)
        return true
    }
}
