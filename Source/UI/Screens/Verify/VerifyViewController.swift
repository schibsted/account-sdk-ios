//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
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
            whatsThisButton.setTitle(viewModel.whatsThis, for: .normal)
            whatsThisButton.titleLabel?.font = theme.fonts.info
            whatsThisButton.contentEdgeInsets.top = 1
        }
    }
    @IBAction func didTapWhatLink(_: UIButton) {
        configuration.tracker?.engagement(.click(on: .rememberMeInfo), in: trackerScreenID)
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
    @IBOutlet var text: NormalLabel! {
        didSet {
            text.text = viewModel.subtext
        }
    }
    @IBOutlet var inputTitle: NormalLabel! {
        didSet {
            inputTitle.text = viewModel.inputTitle
        }
    }
    @IBOutlet var sentToText: NormalLabel! {
        didSet {
            sentToText.text = viewModel.identifier.normalizedString
        }
    }
    @IBOutlet var resend: UIButton! {
        didSet {
            let string = NSAttributedString(string: viewModel.resend, attributes: theme.textAttributes.linkButton)
            resend.setAttributedTitle(string, for: .normal)
        }
    }
    @IBOutlet var changeIdentifier: UIButton! {
        didSet {
            let string = NSAttributedString(string: viewModel.change, attributes: theme.textAttributes.linkButton)
            changeIdentifier.setAttributedTitle(string, for: .normal)
        }
    }
    @IBOutlet var errorText: ErrorLabel! {
        didSet {
            errorText.isHidden = true
        }
    }
    @IBOutlet var verify: PrimaryButton! {
        didSet {
            verify.setTitle(viewModel.proceed, for: .normal)
        }
    }
    @IBOutlet var verifyButtonLayoutGuide: NSLayoutConstraint!
    @IBOutlet var textFieldStackView: UIStackView! {
        didSet {
            let toolbar = UIToolbar.forKeyboard(target: self, doneString: viewModel.done, doneSelector: #selector(didTapVerify))
            maxIndex = textFieldStackView.arrangedSubviews.count
            textFieldStackView.arrangedSubviews.enumerated().forEach {
                guard let codeBox = $1 as? ValidateTextField else {
                    return
                }
                codeBox.delegate = self
                codeBox.contentInset = UIEdgeInsets.zero
                codeBox.keyboardType = .decimalPad
                codeBox.inputAccessoryView = toolbar

                codeBox.isEnabled = true
                codeBox.addTarget(self, action: #selector(textFieldChanged(_:)), for: UIControl.Event.editingChanged)
            }
        }
    }

    let viewModel: VerifyViewModel
    var maxIndex = 0
    private var currentIndex = 0

    private static let zeroWidthSpace = "\u{200B}"

    var enteredCode: String {
        return textFieldStackView.arrangedSubviews.reduce("") { [weak self] memo, codeBox in
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

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(stackViewClicked(_:)))
        textFieldStackView.addGestureRecognizer(tapGesture)

        viewToEnsureVisibilityOfAfterKeyboardAppearance = textFieldStackView
    }

    override var navigationTitle: String {
        return viewModel.title
    }

    @IBAction func didTapResend(_: UIButton) {
        configuration.tracker?.engagement(.click(on: .resend), in: trackerScreenID)
        didRequestAction?(.resendCode)
    }

    @IBAction func didTapVerify(_: UIButton) {
        verifyCode()
    }

    @objc func verifyCode() {
        configuration.tracker?.interaction(.submit, with: trackerScreenID, additionalFields: [.keepLoggedIn(shouldPersistUserCheck.isChecked)])
        guard enteredCode.count == VerifyViewModel.numberOfCodeDigits else {
            showInlineError(.invalidCode)
            return
        }

        didRequestAction?(.enter(code: enteredCode, shouldPersistUser: shouldPersistUserCheck.isChecked))
    }

    @IBAction func didTapChangeIdentifier(_: UIButton) {
        didRequestAction?(.changeIdentifier)
    }

    fileprivate func resetError() {
        textFieldStackView.arrangedSubviews.forEach {
            guard let text = $0 as? ValidateTextField else {
                return
            }
            text.isError = false
            text.clearButtonMode = .never
        }
        errorText.text = ""
        errorText.isHidden = false
    }

    override func startLoading() {
        super.startLoading()
        resetError()
        verify.isAnimating = true
        navigationController?.navigationBar.isUserInteractionEnabled = false
    }

    override func endLoading() {
        super.endLoading()
        verify.isAnimating = false
        navigationController?.navigationBar.isUserInteractionEnabled = true
    }

    @discardableResult override func showInlineError(_ error: ClientError) -> Bool {
        let message: String
        switch error {
        case .invalidCode:
            message = viewModel.invalidCode
        default:
            return false
        }

        textFieldStackView.arrangedSubviews.forEach {
            guard let textField = $0 as? ValidateTextField else {
                return
            }
            textField.isError = true
        }
        errorText.text = message
        errorText.isHidden = false
        configuration.tracker?.error(.validation(error), in: trackerScreenID)

        return true
    }
}

extension VerifyViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        verifyCode()
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let codeBox = textField as? TextField,
            let index = textFieldStackView.arrangedSubviews.index(of: codeBox)
        else {
            return false
        }

        if index != currentIndex {
            nextField(index: currentIndex)
            return false
        }

        return true
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
        return isValidUpdate(code: newText)
    }

    private func isValidUpdate(code: String) -> Bool {
        let normalized = normalizeCodeText(code)
        if normalized.isEmpty {
            return true
        }

        // validate to only allow single digits
        let hasOnlyDigits = normalized.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil

        if normalized.count == VerifyViewModel.numberOfCodeDigits, hasOnlyDigits {
            updateAllTextFields(numbers: normalized.map(String.init))
            return false
        }

        return (normalized.count == 1) && hasOnlyDigits
    }

    @objc func textFieldChanged(_ sender: UITextField) {
        resetError()
        handleTextFieldChange(code: sender.text ?? "")
    }

    @objc func stackViewClicked(_: AnyObject) {
        nextField(index: currentIndex)
    }

    private func normalizeCodeText(_ text: String) -> String {
        if text.hasPrefix(type(of: self).zeroWidthSpace) {
            return String(text.dropFirst())
        } else {
            return text
        }
    }

    private func handleTextFieldChange(code: String) {
        let normalText = normalizeCodeText(code)
        if normalText.isEmpty {
            let prevIndex = currentIndex - 1
            if prevIndex >= 0 {
                currentIndex = prevIndex
                previousField(index: prevIndex)
            }
        } else {
            let nextIndex = currentIndex + 1
            if nextIndex < maxIndex {
                currentIndex = nextIndex
                nextField(index: nextIndex)
            }
        }
    }
}

extension VerifyViewController {
    func nextField(index: Int) {
        guard let textfield = textFieldStackView.arrangedSubviews[index] as? TextField else {
            return
        }

        textfield.isEnabled = true
        textfield.becomeFirstResponder()
    }

    func previousField(index: Int) {
        guard let textfield = textFieldStackView.arrangedSubviews[index] as? TextField else {
            return
        }

        textfield.text = ""
        textfield.becomeFirstResponder()
    }

    func updateAllTextFields(numbers: [String]) {
        textFieldStackView.arrangedSubviews.enumerated().forEach {
            guard let text = $1 as? ValidateTextField else {
                return
            }

            text.text = numbers[$0]
            self.handleTextFieldChange(code: numbers[$0])
        }
    }
}
