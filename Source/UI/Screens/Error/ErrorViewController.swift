//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

class ErrorViewController: IdentityUIViewController {
    @IBOutlet var headingLabel: Heading! {
        didSet {
            switch self.dataSource {
            case .clientError:
                self.headingLabel.text = self.strings.heading
            case let .customText(title, _):
                self.headingLabel.text = title
            }
        }
    }

    @IBOutlet var descriptionLabel: NormalLabel! {
        didSet {
            switch self.dataSource {
            case let .clientError(error):
                self.descriptionLabel.text = error.localized(from: self.configuration.localizationBundle)
            case let .customText(_, description):
                self.descriptionLabel.text = description
            }
        }
    }

    @IBOutlet var okButton: PrimaryButton! {
        didSet {
            self.okButton.setTitle(self.strings.proceed, for: .normal)
        }
    }
    @IBOutlet var sheetBackgroundView: UIView!

    private enum DataSource {
        case clientError(ClientError)
        case customText(title: String, description: String)
    }

    private let dataSource: DataSource
    let strings: ErrorScreenStrings
    private weak var originViewController: IdentityUIViewController?

    convenience init(
        configuration: IdentityUIConfiguration,
        customText: (title: String, description: String),
        from originViewController: IdentityUIViewController?,
        strings: ErrorScreenStrings
    ) {
        self.init(
            dataSource: .customText(title: customText.title, description: customText.description),
            from: originViewController,
            configuration: configuration,
            strings: strings
        )
    }

    convenience init(
        configuration: IdentityUIConfiguration,
        error: ClientError,
        from originViewController: IdentityUIViewController?,
        strings: ErrorScreenStrings
    ) {
        self.init(
            dataSource: .clientError(error),
            from: originViewController,
            configuration: configuration,
            strings: strings
        )
    }

    private init(
        dataSource: DataSource,
        from originViewController: IdentityUIViewController?,
        configuration: IdentityUIConfiguration,
        strings: ErrorScreenStrings
    ) {
        self.dataSource = dataSource
        self.strings = strings
        self.originViewController = originViewController
        super.init(configuration: configuration, navigationSettings: NavigationSettings(), trackerScreenID: .popup(.error))
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func didTapOKButton(_: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sheetBackgroundView.layer.cornerRadius = self.theme.geometry.cornerRadius
        self.sheetBackgroundView.clipsToBounds = true

        guard let originViewController = self.originViewController else {
            return
        }

        let errorType: TrackingEvent.ErrorType
        switch self.dataSource {
        case let .clientError(error):
            if case .networkingError = error {
                errorType = .network(error)
            } else {
                errorType = .generic(error)
            }
        case let .customText(title, description):
            let nsError = NSError(domain: title, code: 0, userInfo: [
                NSLocalizedDescriptionKey: description,
            ])
            errorType = .generic(nsError)
        }

        self.configuration.tracker?.error(errorType, in: originViewController.trackerScreenID)
    }
}
