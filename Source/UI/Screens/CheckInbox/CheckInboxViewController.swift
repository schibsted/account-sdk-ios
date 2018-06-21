//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
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
            let string = self.viewModel.sentLink + "\n" + self.viewModel.identifier.normalizedString
            self.textLabel.attributedText = NSAttributedString(
                string: string,
                attributes: self.theme.textAttributes.centeredNormalParagraph
            )
        }
    }

    @IBOutlet var changeButton: UIButton! {
        didSet {
            self.changeButton.titleLabel?.font = self.theme.fonts.normal
            self.changeButton.setTitle(self.viewModel.change, for: .normal)
        }
    }

    @IBAction func didClickChangeButton(_: Any) {
        self.didRequestAction?(.changeIdentifier)
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
        return self.viewModel.title
    }
}
