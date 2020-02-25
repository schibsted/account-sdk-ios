//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class ResendViewController: IdentityUIViewController {
    enum Action {
        case changeIdentifier
    }

    var didRequestAction: ((Action) -> Void)?

    @IBOutlet var header: Heading! {
        didSet {
            header.text = viewModel.header
        }
    }
    @IBOutlet var code: NormalLabel! {
        didSet {
            code.font = theme.fonts.normal
            code.text = viewModel.subtext
        }
    }
    @IBOutlet var number: NormalLabel! {
        didSet {
            number.font = theme.fonts.normal
            number.text = viewModel.identifier.normalizedString
        }
    }
    @IBOutlet var edit: SecondaryButton! {
        didSet {
            edit.setTitle(viewModel.editText, for: .normal)
        }
    }
    @IBOutlet var ok: PrimaryButton! {
        didSet {
            ok.setTitle(viewModel.proceed, for: .normal)
        }
    }
    @IBOutlet var stackBackground: UIView!

    let viewModel: ResendViewModel

    init(configuration: IdentityUIConfiguration, viewModel: ResendViewModel) {
        self.viewModel = viewModel
        super.init(configuration: configuration, navigationSettings: NavigationSettings(), trackerScreenID: .popup(.resend))
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        stackBackground.layer.cornerRadius = theme.geometry.cornerRadius
        stackBackground.clipsToBounds = true
    }

    @IBAction func didTapContinue(_: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func didTapEdit(_: UIButton) {
        dismiss(animated: true)
        didRequestAction?(.changeIdentifier)
    }
}
