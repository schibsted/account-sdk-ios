//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class CheckInboxViewController: IdentityUIViewController {
    enum Action {
        case changeIdentifier
        case cancel
    }

    var didRequestAction: ((Action) -> Void)?

    @IBOutlet var textLabel: NormalLabel! {
        didSet {
            let string = viewModel.sentLink + "\n" + viewModel.identifier.normalizedString
            textLabel.attributedText = NSAttributedString(
                string: string,
                attributes: theme.textAttributes.centeredNormalParagraph
            )
        }
    }

    @IBOutlet var changeButton: UIButton! {
        didSet {
            changeButton.titleLabel?.font = theme.fonts.normal
            changeButton.setTitle(viewModel.change, for: .normal)
        }
    }

    @IBAction func didClickChangeButton(_: Any) {
        didRequestAction?(.changeIdentifier)
    }

    private let viewModel: CheckInboxViewModel

    init(configuration: IdentityUIConfiguration, navigationSettings: NavigationSettings, viewModel: CheckInboxViewModel) {
        self.viewModel = viewModel
        super.init(configuration: configuration, navigationSettings: navigationSettings, trackerScreenID: .accountVerification)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var navigationTitle: String {
        return viewModel.title
    }
}
