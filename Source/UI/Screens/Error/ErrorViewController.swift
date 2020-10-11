//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class ErrorViewController: IdentityUIViewController {
    enum Action {
        case dismiss
    }

    var didRequestAction: ((Action) -> Void)?

    @IBOutlet var headingLabel: Heading! {
        didSet {
            switch dataSource {
            case .clientError:
                headingLabel.text = strings.heading
            case let .customText(title, _):
                headingLabel.text = title
            }
        }
    }

    @IBOutlet var descriptionLabel: NormalLabel! {
        didSet {
            switch dataSource {
            case let .clientError(error):
                descriptionLabel.text = error.localized(from: configuration.localizationBundle)
            case let .customText(_, description):
                descriptionLabel.text = description
            }
        }
    }

    @IBOutlet var okButton: PrimaryButton! {
        didSet {
            okButton.setTitle(strings.proceed, for: .normal)
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
        customText: (title: String?, description: String),
        from originViewController: IdentityUIViewController?,
        strings: ErrorScreenStrings
    ) {
        self.init(
            dataSource: .customText(title: customText.title ?? strings.heading, description: customText.description),
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
        dismiss(animated: true) { [weak self] in
            self?.didRequestAction?(.dismiss)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sheetBackgroundView.layer.cornerRadius = theme.geometry.cornerRadius
        sheetBackgroundView.clipsToBounds = true

        guard let originViewController = self.originViewController else {
            return
        }

        let errorType: TrackingEvent.ErrorType
        switch dataSource {
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

        configuration.tracker?.error(errorType, in: originViewController.trackerScreenID)
    }
}
