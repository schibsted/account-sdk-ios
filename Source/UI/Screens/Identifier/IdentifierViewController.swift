//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

enum IdentifierViewControllerAction {
    case enter(identifier: Identifier)
    case showHelp(url: URL)
    case back
    case skip
}

private struct Constants {
    static let EmailStorageLabel = "com.schibsted.account.user.email"
}

class IdentifierViewController: IdentityUIViewController {
    var didRequestAction: ((IdentifierViewControllerAction) -> Void)?

    @IBOutlet var whastThisButton: UIButton! {
        didSet {
            whastThisButton.setTitle(viewModel.whatsThis, for: .normal)
            whastThisButton.titleLabel?.font = theme.fonts.info
            whastThisButton.contentEdgeInsets.top = 1
            whastThisButton.isHidden = configuration.disableWhatsThisButton
        }
    }
    @IBOutlet var backgroundView: UIView! {
        didSet {
            backgroundView.backgroundColor = .schibstedLightGray
        }
    }
    @IBAction func didTapWhatsThis(_: UIButton) {
        configuration.tracker?.engagement(.click(on: .whatsSchibstedAccount), in: trackerScreenID)
        didRequestAction?(.showHelp(url: viewModel.helpURL))
    }

    @IBOutlet var teaserView: UIView! {
        didSet {
            teaserView.isHidden = teaser.text?.isEmpty != false
        }
    }
    @IBOutlet var teaser: NormalLabel! {
        didSet {
            teaser.text = viewModel.localizedTeaserText
        }
    }
    @IBOutlet var countryCode: TextField! {
        didSet {
            countryCode.text = "\(CountryDialingCodeHelper.currentDialingCode())"
            countryCode.keyboardType = .phonePad
            countryCode.delegate = self
        }
    }
    @IBOutlet var emailAddress: TextField! {
        didSet {
            emailAddress.keyboardType = .emailAddress
            emailAddress.autocorrectionType = .no
            emailAddress.delegate = self
            emailAddress.isHidden = true
            emailAddress.clearButtonMode = .whileEditing

            if #available(iOS 11.0, *) {
                self.emailAddress.textContentType = .username
            }
        }
    }
    @IBOutlet var phoneNumber: TextField! {
        didSet {
            phoneNumber.keyboardType = .phonePad
            phoneNumber.delegate = self
            phoneNumber.clearButtonMode = .whileEditing
        }
    }
    @IBOutlet var numberStackView: UIStackView! {
        didSet {
            numberStackView.isHidden = true
        }
    }
    @IBOutlet var inputTitle: NormalLabel! {
        didSet {
            inputTitle.text = viewModel.inputTitle
        }
    }
    @IBOutlet var infoText: UILabel! {
        didSet {
            infoText.attributedText = NSAttributedString(
                string: viewModel.infoText,
                attributes: theme.textAttributes.smallParagraph
            )
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
    @IBOutlet var skipButton: SecondaryButton! {
        didSet {
            skipButton.setTitle(viewModel.skip, for: .normal)
        }
    }

    @IBAction func didTapSubmitButton(_: UIButton) {
        didRequestAction?(.skip)
    }

    let viewModel: IdentifierViewModel

    init(configuration: IdentityUIConfiguration, navigationSettings: NavigationSettings, viewModel: IdentifierViewModel) {
        self.viewModel = viewModel

        let trackerScreenID: TrackingEvent.Screen
        switch viewModel.loginMethod.authenticationType {
        case .password:
            trackerScreenID = .passwordIdentificationForm
        case .passwordless:
            trackerScreenID = .passwordlessIdentificationForm
        }

        super.init(
            configuration: configuration,
            navigationSettings: navigationSettings,
            trackerScreenID: trackerScreenID,
            trackerViewAdditionalFields: [.teaser(viewModel.localizedTeaserText != nil)]
        )
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let toolbar = UIToolbar.forKeyboard(target: self, doneString: viewModel.done, doneSelector: #selector(didTapContinue))

        func showEmailAddress() {
            emailAddress.isHidden = false
            emailAddress.inputAccessoryView = toolbar
        }

        func showPhoneNumber() {
            numberStackView.isHidden = false
            countryCode.inputAccessoryView = toolbar
            phoneNumber.inputAccessoryView = toolbar
        }

        switch self.viewModel.loginMethod {
        case .email, .password:
            showEmailAddress()
            viewToEnsureVisibilityOfAfterKeyboardAppearance = emailAddress
            if let savedEmail = Settings.value(forKey: Constants.EmailStorageLabel) {
                emailAddress.text = savedEmail as? String
            }
        case let .emailWithPrefilledValue(prefilledEmail), let .passwordWithPrefilledEmail(prefilledEmail):
            showEmailAddress()
            emailAddress.text = prefilledEmail.normalizedString
        case .phone:
            showPhoneNumber()
            viewToEnsureVisibilityOfAfterKeyboardAppearance = phoneNumber
        case let .phoneWithPrefilledValue(prefilledPhoneComponents):
            showPhoneNumber()
            countryCode.text = prefilledPhoneComponents.countryCode
            phoneNumber.text = prefilledPhoneComponents.number
        case .sharedWebCredentials:
            fatalError()
        }

        skipButton.isHidden = !self.configuration.isSkippable
    }

    @IBAction func didTapContinue(_: UIButton) {
        continueToNextPage()
    }

    @objc private func continueToNextPage() {
        self.configuration.tracker?.interaction(.submit, with: self.trackerScreenID)

        let identifier: Identifier

        switch self.viewModel.loginMethod.identifierType {
        case .email:
            guard let text = emailAddress.text?.trimmingCharacters(in: .whitespaces) else {
                return
            }
            guard let email = EmailAddress(text) else {
                showInlineError(.invalidEmail)
                return
            }
            identifier = Identifier(email)
        case .phone:
            let countryCodeText = (countryCode.text ?? "").trimmingCharacters(in: .whitespaces)
            let numberText = (phoneNumber.text ?? "").trimmingCharacters(in: .whitespaces)
            guard let phone = PhoneNumber(countryCode: countryCodeText, number: numberText) else {
                showInlineError(.invalidPhoneNumber)
                return
            }
            identifier = Identifier(phone)
        }

        didRequestAction?(.enter(identifier: identifier))
    }

    override var navigationTitle: String {
        return self.viewModel.title
    }

    override func startLoading() {
        super.startLoading()
        inputError.isHidden = true
        switch self.viewModel.loginMethod.identifierType {
        case .phone:
            countryCode.applyUnfocusedStyle()
            phoneNumber.applyUnfocusedStyle()
        case .email:
            emailAddress.applyUnfocusedStyle()
        }
        continueButton.isAnimating = true
    }

    override func endLoading() {
        super.endLoading()
        continueButton.isAnimating = false
    }

    @discardableResult override func showInlineError(_ error: ClientError) -> Bool {
        let message: String
        switch error {
        case .invalidEmail:
            message = self.viewModel.invalidEmail
        case .invalidPhoneNumber:
            message = self.viewModel.invalidPhoneNumber
        default:
            return false
        }

        self.configuration.tracker?.error(.validation(error), in: self.trackerScreenID)
        inputError.text = message
        inputError.isHidden = false
        switch self.viewModel.loginMethod.identifierType {
        case .email:
            emailAddress.layer.borderColor = theme.colors.errorBorder.cgColor
        case .phone:
            countryCode.layer.borderColor = theme.colors.errorBorder.cgColor
            phoneNumber.layer.borderColor = theme.colors.errorBorder.cgColor
        }

        return true
    }
}

extension IdentifierViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        continueToNextPage()
        return true
    }
}
