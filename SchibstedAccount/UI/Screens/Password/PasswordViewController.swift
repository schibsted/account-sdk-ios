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
    }

    var didRequestAction: ((Action) -> Void)?

    @IBOutlet var shouldPersistUserCheck: Checkbox!
    @IBOutlet var shouldPersistUserText: NormalLabel! {
        didSet {
            self.shouldPersistUserText.text = self.viewModel.persistentLogin
        }
    }
    @IBOutlet var forgotPasswordButton: UIButton! {
        didSet {
            self.forgotPasswordButton.titleLabel?.font = self.theme.fonts.normal
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
        self.configuration.tracker?.engagement(.click(.forgotPassword, self.trackerViewID))
        self.didRequestAction?(.forgotPassword)
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
            guard let strongSelf = self else {
                return
            }
            strongSelf.configuration.tracker?.engagement(.click(.changeIdentifier, strongSelf.trackerViewID))
            self?.didRequestAction?(.changeIdentifier)
        }

        prefereblyActionSheet.addAction(cancelAction)
        prefereblyActionSheet.addAction(changeAction)

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
        super.init(configuration: configuration, navigationSettings: navigationSettings, trackerViewID: .passwordInput)
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
        case .signin:
            self.infoLabel.isHidden = true
            self.infoLabelHeight.constant = 0
            self.forgotPasswordButton.isHidden = false
        }
    }

    @IBAction func didClickContinue(_: Any) {
        guard let password = self.password.text, password.count >= 8 else {
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
