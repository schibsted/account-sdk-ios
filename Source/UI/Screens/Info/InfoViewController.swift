//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class InfoViewController: IdentityUIViewController {
    @IBOutlet var headerLabel: Heading! {
        didSet {
            headerLabel.text = heading
        }
    }
    @IBOutlet var textLabel: UILabel! {
        didSet {
            textLabel.attributedText = NSAttributedString(
                string: text,
                attributes: theme.textAttributes.infoParagraph
            )
        }
    }
    @IBOutlet var ok: PrimaryButton! {
        didSet {
            ok.setTitle("OK", for: .normal)
        }
    }
    @IBOutlet var stackBackground: UIView!
    @IBOutlet var infoImage: UIImageView!

    let titleImage: UIImage?
    let heading: String
    let text: String

    init(configuration: IdentityUIConfiguration, title: String, text: String, titleImage: UIImage?) {
        heading = title
        self.text = text
        self.titleImage = titleImage
        super.init(configuration: configuration, navigationSettings: NavigationSettings(), trackerScreenID: .popup(.info))
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        stackBackground.layer.cornerRadius = theme.geometry.cornerRadius
        stackBackground.clipsToBounds = true
        if let image = self.titleImage {
            infoImage.image = image
        } else {
            infoImage.image = .schibstedInfoPlaceholder
        }
    }

    @IBAction func didTapContinue(_: UIButton) {
        dismiss(animated: true)
    }
}
