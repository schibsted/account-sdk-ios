//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class VerifyViewController: IdentityUIViewController {
    enum Action {
        case enter(code: String, shouldPersistUser: Bool)
        case changeIdentifier
        case resendCode
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
        self.configuration.tracker?.engagement(.click(on: .rememberMeInfo), in: self.trackerScreenID)
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
    @IBOutlet var text: NormalLabel! {
        didSet {
            self.text.text = self.viewModel.subtext
        }
    }
    @IBOutlet var inputTitle: NormalLabel! {
        didSet {
            self.inputTitle.text = self.viewModel.inputTitle
        }
    }
    @IBOutlet var sentToText: NormalLabel! {
        didSet {
            self.sentToText.text = self.viewModel.identifier.normalizedString
        }
    }
    @IBOutlet var resend: UIButton! {
        didSet {
            let string = NSAttributedString(string: self.viewModel.resend, attributes: self.theme.textAttributes.linkButton)
            self.resend.setAttributedTitle(string, for: .normal)
        }
    }
    @IBOutlet var changeIdentifier: UIButton! {
        didSet {
            let string = NSAttributedString(string: self.viewModel.change, attributes: self.theme.textAttributes.linkButton)
            self.changeIdentifier.setAttributedTitle(string, for: .normal)
        }
    }
    @IBOutlet var errorText: ErrorLabel! {
        didSet {
            self.errorText.isHidden = true
        }
    }
    @IBOutlet var verify: PrimaryButton! {
        didSet {
            self.verify.setTitle(self.viewModel.proceed, for: .normal)
        }
    }
    @IBOutlet var verifyButtonLayoutGuide: NSLayoutConstraint!
    @IBOutlet var textFieldStackView: UIStackView! {
        didSet {
            let toolbar = UIToolbar.forKeyboard(target: self, doneString: self.viewModel.done, doneSelector: #selector(self.didClickVerify))
            self.maxIndex = self.textFieldStackView.arrangedSubviews.count
            self.textFieldStackView.arrangedSubviews.enumerated().forEach {
                guard let codeBox = $1 as? ValidateTextField else {
                    return
                }
                codeBox.delegate = self
                codeBox.contentInset = UIEdgeInsets.zero
                codeBox.keyboardType = .decimalPad
                codeBox.inputAccessoryView = toolbar

                codeBox.isEnabled = $0 == 0
                codeBox.addTarget(self, action: #selector(textFieldChanged(_:)), for: UIControl.Event.editingChanged)
            }
        }
    }

    let viewModel: VerifyViewModel
    var maxIndex = 0
    private var currentIndex = 0

    private static let zeroWidthSpace = "\u{200B}"

    var enteredCode: String {
        return self.textFieldStackView.arrangedSubviews.reduce("") { [weak self] memo, codeBox in
            guard let codeBox = codeBox as? TextField else {
                return ""
            }

            return memo + (self?.normalizeCodeText(codeBox.text ?? "") ?? "")
        }
    }

    init(configuration: IdentityUIConfiguration, navigationSettings: NavigationSettings, viewModel: VerifyViewModel) {
        self.viewModel = viewModel
        super.init(configuration: configuration, navigationSettings: navigationSettings, trackerScreenID: .passwordlessInput)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewToEnsureVisibilityOfAfterKeyboardAppearance = self.textFieldStackView
    }

    override var navigationTitle: String {
        return self.viewModel.title
    }

    @IBAction func didClickResend(_: Any) {
        self.configuration.tracker?.engagement(.click(on: .resend), in: self.trackerScreenID)
        self.didRequestAction?(.resendCode)
    }

    @IBAction func didClickVerify(_: Any) {
        self.configuration.tracker?.interaction(.submit, with: self.trackerScreenID, additionalFields: [.keepLoggedIn(self.shouldPersistUserCheck.isChecked)])
        guard self.enteredCode.count == VerifyViewModel.numberOfCodeDigits else {
            self.showInlineError(.invalidCode)
            return
        }

        self.didRequestAction?(.enter(code: self.enteredCode, shouldPersistUser: self.shouldPersistUserCheck.isChecked))
    }

    @IBAction func didClickChangeIdentifier(_: Any) {
        self.didRequestAction?(.changeIdentifier)
    }

    fileprivate func resetError() {
        self.textFieldStackView.arrangedSubviews.forEach {
            guard let text = $0 as? ValidateTextField else {
                return
            }
            text.isError = false
            text.clearButtonMode = .never
        }
        self.errorText.text = ""
        self.errorText.isHidden = false
    }

    override func startLoading() {
        super.startLoading()
        self.resetError()
        self.verify.isAnimating = true
        self.navigationController?.navigationBar.isUserInteractionEnabled = false
    }

    override func endLoading() {
        super.endLoading()
        self.verify.isAnimating = false
        self.navigationController?.navigationBar.isUserInteractionEnabled = true
    }

    @discardableResult override func showInlineError(_ error: ClientError) -> Bool {
        let message: String
        switch error {
        case .invalidCode:
            message = self.viewModel.invalidCode
        default:
            return false
        }

        self.textFieldStackView.arrangedSubviews.forEach {
            guard let textField = $0 as? ValidateTextField else {
                return
            }
            textField.isError = true
        }
        self.errorText.text = message
        self.errorText.isHidden = false
        self.configuration.tracker?.error(.validation(error), in: self.trackerScreenID)

        return true
    }
}

extension VerifyViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.didClickVerify(textField)
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let codeBox = textField as? TextField,
            let index = self.textFieldStackView.arrangedSubviews.index(of: codeBox)
        else {
            return false
        }

        return self.currentIndex == index
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == nil || textField.text?.isEmpty == true {
            // iOS won't emit any change events when hitting delete in an empty
            // UITextField. However, it will if you set the contents to a zero width space!
            textField.text = type(of: self).zeroWidthSpace
        }

        textField.isSelected = true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.isSelected = false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldText = (textField.text ?? "") as NSString
        let newText = oldText.replacingCharacters(in: range, with: string)
        return self.isValidUpdate(code: newText)
    }

    private func isValidUpdate(code: String) -> Bool {
        let normalized = normalizeCodeText(code)
        if normalized.isEmpty {
            return true
        }

        // validate to only allow single digits
        let hasOnlyDigits = normalized.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil

        if normalized.count == VerifyViewModel.numberOfCodeDigits && hasOnlyDigits {
            self.updateAllTextFields(numbers: normalized.map(String.init))
            return false
        }

        return (normalized.count == 1) && hasOnlyDigits
    }

    @objc func textFieldChanged(_ sender: UITextField) {
        self.resetError()
        self.handleTextFieldChange(code: sender.text ?? "")
    }

    private func normalizeCodeText(_ text: String) -> String {
        if text.hasPrefix(type(of: self).zeroWidthSpace) {
            return String(text.dropFirst())
        } else {
            return text
        }
    }

    private func handleTextFieldChange(code: String) {
        let normalText = self.normalizeCodeText(code)
        if normalText.isEmpty {
            let prevIndex = currentIndex - 1
            if prevIndex >= 0 {
                self.currentIndex = prevIndex
                self.previousField(index: prevIndex)
            }
        } else {
            let nextIndex = currentIndex + 1
            if nextIndex < self.maxIndex {
                self.currentIndex = nextIndex
                self.nextField(index: nextIndex)
            }
        }
    }
}

extension VerifyViewController {
    func nextField(index: Int) {
        guard let textfield = self.textFieldStackView.arrangedSubviews[index] as? TextField else {
            return
        }

        textfield.isEnabled = true
        textfield.becomeFirstResponder()
    }

    func previousField(index: Int) {
        guard let textfield = self.textFieldStackView.arrangedSubviews[index] as? TextField else {
            return
        }

        textfield.text = ""
        textfield.becomeFirstResponder()
    }

    func updateAllTextFields(numbers: [String]) {
        self.textFieldStackView.arrangedSubviews.enumerated().forEach {
            guard let text = $1 as? ValidateTextField else {
                return
            }

            text.text = numbers[$0]
            self.handleTextFieldChange(code: numbers[$0])
        }
    }
}
