//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class TermsViewController: IdentityUIViewController {
    enum Action {
        case acceptTerms
        case open(url: URL)
        case back
        case cancel
    }

    var didRequestAction: ((Action) -> Void)?

    @IBOutlet var subtext: NormalLabel! {
        didSet {
            if case .signin = self.viewModel.loginFlowVariant {
                self.subtext.text = self.viewModel.subtextLogin
            } else {
                self.subtext.text = self.viewModel.subtextCreate
            }
        }
    }
    @IBOutlet var termOneText: TextView! {
        didSet {
            self.termOneText.isEditable = false
            self.termOneText.delegate = self
            self.termOneText.attributedText = self.viewModel.termsLink
        }
    }
    @IBOutlet var termOneCheck: Checkbox!
    @IBOutlet var termOneError: ErrorLabel! {
        didSet {
            self.termOneError.isHidden = true
        }
    }
    @IBOutlet var termTwoText: TextView! {
        didSet {
            self.termTwoText.isEditable = false
            self.termTwoText.delegate = self
            self.termTwoText.attributedText = self.viewModel.privacyLink
        }
    }
    @IBOutlet var termTwoCheck: Checkbox!
    @IBOutlet var termTwoError: ErrorLabel! {
        didSet {
            self.termTwoError.isHidden = true
        }
    }

    @IBOutlet var acceptButton: PrimaryButton! {
        didSet {
            self.acceptButton.setTitle(self.viewModel.proceed, for: .normal)
        }
    }

    let viewModel: TermsViewModel

    init(configuration: IdentityUIConfiguration, navigationSettings: NavigationSettings, viewModel: TermsViewModel) {
        self.viewModel = viewModel
        super.init(configuration: configuration, navigationSettings: navigationSettings, trackerScreenID: .terms)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationTitle: String {
        return self.viewModel.title
    }

    @IBAction func didClickContinue(_: Any) {
        let termOneAccepted = self.termOneCheck.isChecked
        let termTwoAccepted = self.termTwoCheck.isChecked

        guard termOneAccepted && termTwoAccepted else {
            self.termsNeedsAccept(termOne: !termOneAccepted, termTwo: !termTwoAccepted)
            return
        }

        self.didRequestAction?(.acceptTerms)
    }

    override func startLoading() {
        super.startLoading()
        self.acceptButton.isAnimating = true
    }

    override func endLoading() {
        super.endLoading()
        self.acceptButton.isAnimating = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        (self.view as? ViewContainingExtendedSubviews)?.extendedSubviews = [
            self.termOneCheck,
            self.termTwoCheck,
        ]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let padding: CGFloat = 8
        let buttonY = self.view.convert(self.acceptButton.frame, from: self.acceptButton.superview).minY
        let buttonAreaHeight = self.view.bounds.height - buttonY + padding
        self.scrollView.contentInset.bottom = max(buttonAreaHeight, 0)
        self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset
    }
}

extension TermsViewController: UITextViewDelegate {
    func textView(_: UITextView, shouldInteractWith url: URL, in _: NSRange) -> Bool {
        let terms = self.viewModel.terms

        if terms.clientPrivacyURL == url {
            self.configuration.tracker?.engagement(.click(on: .privacyClient), in: self.trackerScreenID)
        } else if terms.platformPrivacyURL == url {
            self.configuration.tracker?.engagement(.click(on: .privacySchibstedAccount), in: self.trackerScreenID)
        } else if terms.clientTermsURL == url {
            self.configuration.tracker?.engagement(.click(on: .agreementsClient), in: self.trackerScreenID)
        } else if terms.platformTermsURL == url {
            self.configuration.tracker?.engagement(.click(on: .agreementsSchibstedAccount), in: self.trackerScreenID)
        }

        self.didRequestAction?(.open(url: url))
        return false
    }
}

extension TermsViewController {
    func termsNeedsAccept(termOne: Bool, termTwo: Bool) {
        if termOne {
            self.termOneError.text = self.viewModel.acceptTermError
            self.termOneError.isHidden = false
            self.termOneCheck.tintColor = self.theme.colors.errorBorder
        } else {
            self.termOneError.isHidden = true
        }

        if termTwo {
            self.termTwoError.text = self.viewModel.acceptPrivacyError
            self.termTwoError.isHidden = false
            self.termTwoCheck.tintColor = self.theme.colors.errorBorder
        } else {
            self.termTwoError.isHidden = true
        }

        self.configuration.tracker?.error(.validation(.agreements), in: self.trackerScreenID)
    }
}
