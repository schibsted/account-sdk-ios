//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
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
            if case .signin = viewModel.loginFlowVariant {
                self.subtext.text = self.viewModel.subtextLogin
            } else {
                subtext.text = viewModel.subtextCreate
            }
        }
    }
    @IBOutlet var termOneText: TextView! {
        didSet {
            termOneText.isEditable = false
            termOneText.delegate = self
            termOneText.attributedText = viewModel.termsLink
        }
    }
    @IBOutlet var termOneCheck: Checkbox!
    @IBOutlet var termOneError: ErrorLabel! {
        didSet {
            termOneError.isHidden = true
        }
    }
    @IBOutlet var termTwoText: TextView! {
        didSet {
            termTwoText.isEditable = false
            termTwoText.delegate = self
            termTwoText.attributedText = viewModel.privacyLink
        }
    }
    @IBOutlet var termTwoCheck: Checkbox!
    @IBOutlet var termTwoError: ErrorLabel! {
        didSet {
            termTwoError.isHidden = true
        }
    }

    @IBOutlet var acceptButton: PrimaryButton! {
        didSet {
            acceptButton.setTitle(viewModel.proceed, for: .normal)
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
        return viewModel.title
    }

    @IBAction func didTapContinue(_: UIButton) {
        let termOneAccepted = termOneCheck.isChecked
        let termTwoAccepted = termTwoCheck.isChecked

        guard termOneAccepted, termTwoAccepted else {
            termsNeedsAccept(termOne: !termOneAccepted, termTwo: !termTwoAccepted)
            return
        }

        didRequestAction?(.acceptTerms)
    }

    override func startLoading() {
        super.startLoading()
        acceptButton.isAnimating = true
    }

    override func endLoading() {
        super.endLoading()
        acceptButton.isAnimating = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        (view as? ViewContainingExtendedSubviews)?.extendedSubviews = [
            termOneCheck,
            termTwoCheck,
        ]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let padding: CGFloat = 8
        let buttonY = view.convert(acceptButton.frame, from: acceptButton.superview).minY
        let buttonAreaHeight = view.bounds.height - buttonY + padding
        scrollView.contentInset.bottom = max(buttonAreaHeight, 0)
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }
}

extension TermsViewController: UITextViewDelegate {
    func textView(_: UITextView, shouldInteractWith url: URL, in _: NSRange) -> Bool {
        let terms = viewModel.terms

        if terms.clientPrivacyURL == url {
            configuration.tracker?.engagement(.click(on: .privacyClient), in: trackerScreenID)
        } else if terms.platformPrivacyURL == url {
            configuration.tracker?.engagement(.click(on: .privacySchibstedAccount), in: trackerScreenID)
        } else if terms.clientTermsURL == url {
            configuration.tracker?.engagement(.click(on: .agreementsClient), in: trackerScreenID)
        } else if terms.platformTermsURL == url {
            configuration.tracker?.engagement(.click(on: .agreementsSchibstedAccount), in: trackerScreenID)
        }

        didRequestAction?(.open(url: url))
        return false
    }
}

extension TermsViewController {
    func termsNeedsAccept(termOne: Bool, termTwo: Bool) {
        if termOne {
            termOneError.text = viewModel.acceptTermError
            termOneError.isHidden = false
            termOneCheck.tintColor = theme.colors.errorBorder
        } else {
            termOneError.isHidden = true
        }

        if termTwo {
            termTwoError.text = viewModel.acceptPrivacyError
            termTwoError.isHidden = false
            termTwoCheck.tintColor = theme.colors.errorBorder
        } else {
            termTwoError.isHidden = true
        }

        configuration.tracker?.error(.validation(.agreements), in: trackerScreenID)
    }
}
