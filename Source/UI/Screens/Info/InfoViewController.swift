//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class InfoViewController: IdentityUIViewController {
    @IBOutlet var headerLabel: Heading! {
        didSet {
            self.headerLabel.text = self.heading
        }
    }
    @IBOutlet var textLabel: UILabel! {
        didSet {
            self.textLabel.attributedText = NSAttributedString(
                string: self.text,
                attributes: self.theme.textAttributes.infoParagraph
            )
        }
    }
    @IBOutlet var ok: PrimaryButton! {
        didSet {
            self.ok.setTitle("OK", for: .normal)
        }
    }
    @IBOutlet var stackBackground: UIView!
    @IBOutlet var infoImage: UIImageView!

    let titleImage: UIImage?
    let heading: String
    let text: String

    init(configuration: IdentityUIConfiguration, title: String, text: String, titleImage: UIImage?) {
        self.heading = title
        self.text = text
        self.titleImage = titleImage
        super.init(configuration: configuration, navigationSettings: NavigationSettings(), trackerScreenID: .popup(.info))
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.stackBackground.layer.cornerRadius = self.theme.geometry.cornerRadius
        self.stackBackground.clipsToBounds = true
        if let image = self.titleImage {
            self.infoImage.image = image
        } else {
            self.infoImage.image = .schibstedInfoPlaceholder
        }
    }

    @IBAction func didClickContinue(_: Any) {
        self.dismiss(animated: true)
    }
}
