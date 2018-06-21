//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

enum IdentifierViewControllerAction {
    case enter(identifier: Identifier)
    case showHelp(url: URL)
    case back
    case skip
}

class IdentifierViewController: IdentityUIViewController {
    var didRequestAction: ((IdentifierViewControllerAction) -> Void)?

    @IBOutlet var whastThisButton: UIButton! {
        didSet {
            self.whastThisButton.setTitle(self.viewModel.whatsThis, for: .normal)
            self.whastThisButton.titleLabel?.font = self.theme.fonts.info
            self.whastThisButton.contentEdgeInsets.top = 1
        }
    }
    @IBOutlet var backgroundView: UIView! {
        didSet {
            self.backgroundView.backgroundColor = .schibstedLightGray
        }
    }
    @IBOutlet var contentView: UIView! {
        didSet {
            self.contentView.layer.cornerRadius = self.theme.geometry.contentGroupingCornerRadius
        }
    }
    @IBAction func didClickWhatsThis(_: Any) {
        self.configuration.tracker?.engagement(.click(on: .whatsSchibstedAccount), in: self.trackerScreenID)
        self.didRequestAction?(.showHelp(url: self.viewModel.helpURL))
    }

    @IBOutlet var teaserView: UIView! {
        didSet {
            self.teaserView.isHidden = self.teaser.text?.isEmpty != false
        }
    }
    @IBOutlet var teaser: NormalLabel! {
        didSet {
            self.teaser.text = self.viewModel.localizedTeaserText
        }
    }
    @IBOutlet var countryCode: TextField! {
        didSet {
            self.countryCode.text = "\(CountryDialingCodeHelper.currentDialingCode())"
            self.countryCode.keyboardType = .phonePad
            self.countryCode.delegate = self
        }
    }
    @IBOutlet var emailAddress: TextField! {
        didSet {
            self.emailAddress.keyboardType = .emailAddress
            self.emailAddress.autocorrectionType = .no
            self.emailAddress.delegate = self
            self.emailAddress.isHidden = true
            self.emailAddress.clearButtonMode = .whileEditing
        }
    }
    @IBOutlet var phoneNumber: TextField! {
        didSet {
            self.phoneNumber.keyboardType = .phonePad
            self.phoneNumber.delegate = self
            self.phoneNumber.clearButtonMode = .whileEditing
        }
    }
    @IBOutlet var numberStackView: UIStackView! {
        didSet {
            self.numberStackView.isHidden = true
        }
    }
    @IBOutlet var inputTitle: NormalLabel! {
        didSet {
            self.inputTitle.text = self.viewModel.inputTitle
        }
    }
    @IBOutlet var infoText: UILabel! {
        didSet {
            self.infoText.attributedText = NSAttributedString(
                string: self.viewModel.infoText,
                attributes: self.theme.textAttributes.smallParagraph
            )
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
    @IBOutlet var skipButton: SecondaryButton! {
        didSet {
            self.skipButton.setTitle(self.viewModel.skip, for: .normal)
        }
    }

    @IBAction func didClickSubmitButton(_: Any) {
        self.didRequestAction?(.skip)
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

        let toolbar = UIToolbar.forKeyboard(target: self, doneString: self.viewModel.done, doneSelector: #selector(self.didClickContinue))

        func showEmailAddress() {
            self.emailAddress.isHidden = false
            self.emailAddress.inputAccessoryView = toolbar
        }

        func showPhoneNumber() {
            self.numberStackView.isHidden = false
            self.countryCode.inputAccessoryView = toolbar
            self.phoneNumber.inputAccessoryView = toolbar
        }

        switch self.viewModel.loginMethod {
        case .email, .password:
            showEmailAddress()
            self.viewToEnsureVisibilityOfAfterKeyboardAppearance = self.emailAddress
        case let .emailWithPrefilledValue(prefilledEmail), let .passwordWithPrefilledEmail(prefilledEmail):
            showEmailAddress()
            self.emailAddress.text = prefilledEmail.normalizedString
        case .phone:
            showPhoneNumber()
            self.viewToEnsureVisibilityOfAfterKeyboardAppearance = self.phoneNumber
        case let .phoneWithPrefilledValue(prefilledPhone):
            showPhoneNumber()
            let (countryCodeText, numberText) = prefilledPhone.normalizedValue
            self.countryCode.text = countryCodeText
            self.phoneNumber.text = numberText
        }

        self.skipButton.isHidden = !self.configuration.isSkippable
    }

    @IBAction func didClickContinue(_: Any) {
        self.configuration.tracker?.interaction(.submit, with: self.trackerScreenID)

        let identifier: Identifier

        switch self.viewModel.loginMethod.identifierType {
        case .email:
            guard let text = self.emailAddress.text?.trimmingCharacters(in: .whitespaces) else {
                return
            }
            guard let email = EmailAddress(text) else {
                self.showInlineError(.invalidEmail)
                return
            }
            identifier = Identifier(email)
        case .phone:
            let countryCodeText = (self.countryCode.text ?? "").trimmingCharacters(in: .whitespaces)
            let numberText = (self.phoneNumber.text ?? "").trimmingCharacters(in: .whitespaces)
            guard let phone = PhoneNumber(countryCode: countryCodeText, number: numberText) else {
                self.showInlineError(.invalidPhoneNumber)
                return
            }
            identifier = Identifier(phone)
        }

        self.didRequestAction?(.enter(identifier: identifier))
    }

    override var navigationTitle: String {
        return self.viewModel.title
    }

    override func startLoading() {
        super.startLoading()
        self.inputError.isHidden = true
        switch self.viewModel.loginMethod.identifierType {
        case .phone:
            self.countryCode.applyUnfocusedStyle()
            self.phoneNumber.applyUnfocusedStyle()
        case .email:
            self.emailAddress.applyUnfocusedStyle()
        }
        self.continueButton.isAnimating = true
    }

    override func endLoading() {
        super.endLoading()
        self.continueButton.isAnimating = false
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
        self.inputError.text = message
        self.inputError.isHidden = false
        switch self.viewModel.loginMethod.identifierType {
        case .email:
            self.emailAddress.layer.borderColor = self.theme.colors.errorBorder.cgColor
        case .phone:
            self.countryCode.layer.borderColor = self.theme.colors.errorBorder.cgColor
            self.phoneNumber.layer.borderColor = self.theme.colors.errorBorder.cgColor
        }

        return true
    }
}

extension IdentifierViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.didClickContinue(textField)
        return true
    }
}
