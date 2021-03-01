//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
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
            whatsThisButton.setTitle(viewModel.whatsThis, for: .normal)
            whatsThisButton.titleLabel?.font = theme.fonts.info
            whatsThisButton.contentEdgeInsets.top = 1
        }
    }
    @IBAction func didTapWhatLink(_: UIButton) {
        configuration.tracker?.engagement(.click(on: .learnMoreAboutSchibsted), in: trackerScreenID)
        didRequestAction?(.info(
            title: viewModel.persistentLogin,
            text: viewModel.rememberMe
        ))
    }

    var didRequestAction: ((Action) -> Void)?

    @IBOutlet var shouldPersistUserCheck: Checkbox! {
        didSet {
            shouldPersistUserCheck.isChecked = true
        }
    }
    @IBOutlet var shouldPersistUserText: NormalLabel! {
        didSet {
            shouldPersistUserText.text = viewModel.persistentLogin
        }
    }
    @IBOutlet var forgotPasswordButton: SecondaryButton! {
        didSet {
            forgotPasswordButton.setTitle(viewModel.forgotPassword, for: .normal)
            forgotPasswordButton.isHidden = true
        }
    }
    @IBOutlet var infoLabelHeight: NSLayoutConstraint! {
        didSet {
            infoLabelHeight.constant = 0
        }
    }
    @IBOutlet var changeIdentifierButton: UIButton! {
        didSet {
            let image = UIImage(cgImage: theme.icons.chevronLeft.cgImage!, scale: theme.icons.chevronLeft.scale, orientation: .rightMirrored)
            changeIdentifierButton.setImage(image, for: .normal)
            changeIdentifierButton.addTarget(self, action: #selector(changeIdentifier), for: .touchUpInside)
        }
    }

    @IBAction func didTapForgotPassword(_: UIButton) {
        configuration.tracker?.engagement(.click(on: .forgotPassword), in: trackerScreenID)
        didRequestAction?(.forgotPassword)
    }

    @IBOutlet var ageLabel: InfoLabel! {
        didSet {
            ageLabel.text = viewModel.ageLimit
            ageLabel.isHidden = true
        }
    }
    @IBOutlet var infoLabel: InfoLabel! {
        didSet {
            infoLabel.text = viewModel.info
            infoLabel.isHidden = true
        }
    }
    @IBOutlet var identifierLabel: NormalLabel! {
        didSet {
            identifierLabel.text = viewModel.identifier.originalString
        }
    }
    @IBOutlet var newAccountCreateInfoLabel: UILabel! {
        didSet {
            newAccountCreateInfoLabel.text = viewModel.creatingNewAccountNotice
        }
    }
    @IBOutlet var newAccountCreateNoticeHeader: UIView!

    @objc func changeIdentifier() {
        let prefereblyActionSheet = UIAlertController(title: viewModel.identifier.originalString, message: nil, preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: viewModel.cancel, style: .cancel, handler: nil)
        let changeAction = UIAlertAction(title: viewModel.change, style: .default) { [weak self] _ in
            self?.didRequestAction?(.changeIdentifier)
        }

        prefereblyActionSheet.addAction(cancelAction)
        prefereblyActionSheet.addAction(changeAction)

        if let popoverController = prefereblyActionSheet.popoverPresentationController {
            popoverController.sourceView = changeIdentifierButton
            popoverController.sourceRect = CGRect(x: changeIdentifierButton.bounds.minX, y: changeIdentifierButton.bounds.maxY, width: 0, height: 0)
            popoverController.permittedArrowDirections = [.right]
        }

        present(prefereblyActionSheet, animated: true, completion: nil)
    }

    @IBOutlet var password: PasswordTextField! {
        didSet {
            password.delegate = self
        }
    }
    @IBOutlet var inputTitle: NormalLabel! {
        didSet {
            inputTitle.text = viewModel.inputTitle
        }
    }
    @IBOutlet var continueButton: PrimaryButton! {
        didSet {
            continueButton.setTitle(viewModel.proceed, for: .normal)
        }
    }
    @IBOutlet var inputError: ErrorLabel! {
        didSet {
            inputError.isHidden = true
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

        let toolbar = UIToolbar.forKeyboard(target: self, doneString: viewModel.done, doneSelector: #selector(didTapContinue))

        password.inputAccessoryView = toolbar
        viewToEnsureVisibilityOfAfterKeyboardAppearance = password

        switch viewModel.loginFlowVariant {
        case .signup:
            infoLabel.isHidden = false
            infoLabelHeight.constant = 200 // (less than or equal of some big value).
            forgotPasswordButton.isHidden = true
            ageLabel.isHidden = false
            newAccountCreateNoticeHeader.isHidden = false
            continueButton.setTitle(viewModel.createAccount, for: .normal)
        case .signin:
            infoLabel.isHidden = true
            infoLabelHeight.constant = 0
            forgotPasswordButton.isHidden = false
            newAccountCreateNoticeHeader.isHidden = true
        }
    }

    @IBAction func didTapContinue(_: UIButton) {
        continueToNextPage()
    }

    @objc private func continueToNextPage() {
        self.configuration.tracker?.interaction(.submit, with: self.trackerScreenID, additionalFields: [.keepLoggedIn(self.shouldPersistUserCheck.isChecked)])
        guard let password = self.password.text, (self.viewModel.loginFlowVariant == .signin && password.count >= 1) || password.count >= 8 else {
            self.showInlineError(.passwordTooShort)
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
        inputError.isHidden = true
        password.applyUnfocusedStyle()
        continueButton.isAnimating = true
    }

    override func endLoading() {
        super.endLoading()
        continueButton.isAnimating = false
    }

    @discardableResult override func showInlineError(_ error: ClientError) -> Bool {
        let message: String
        switch error {
        case .invalidUserCredentials:
            message = viewModel.invalidPassword
        case .passwordTooShort:
            message = viewModel.passwordTooShort
        default:
            return false
        }

        configuration.tracker?.error(.validation(error), in: trackerScreenID)

        inputError.text = message
        inputError.isHidden = false
        password.layer.borderColor = theme.colors.errorBorder.cgColor

        return true
    }
}

extension PasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        continueToNextPage()
        return true
    }
}
