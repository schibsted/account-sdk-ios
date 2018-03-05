//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class TermsSummaryViewController: IdentityUIViewController {
    @IBOutlet var contentView: UIView!

    @IBOutlet var headerLabel: Heading! {
        didSet {
            self.headerLabel.font = self.configuration.theme.fonts.title
            self.headerLabel.text = self.viewModel.title
            self.headerLabel.numberOfLines = 0
        }
    }

    @IBOutlet var summaryText: UITextView! {
        didSet {
            self.summaryText.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 24)
            guard let htmlData = self.viewModel.summary.data(using: .utf8) else {
                return
            }
            guard let attributedString = try? NSMutableAttributedString(
                data: htmlData,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                ],
                documentAttributes: nil
            ) else {
                return
            }

            attributedString.beginEditing()
            attributedString.enumerateAttribute(
                .font,
                in: NSRange(location: 0, length: attributedString.length),
                options: NSAttributedString.EnumerationOptions(rawValue: 0)
            ) { value, range, _ in
                guard let oldFont = value as? UIFont else {
                    return
                }
                let normalFont = self.theme.fonts.normal
                guard let adjustedDescriptor = normalFont.fontDescriptor.withSymbolicTraits(oldFont.fontDescriptor.symbolicTraits) else {
                    return
                }
                let adjustedFont = UIFont(descriptor: adjustedDescriptor, size: oldFont.pointSize)
                attributedString.addAttribute(.font, value: adjustedFont, range: range)
            }
            attributedString.endEditing()

            self.summaryText.attributedText = attributedString
        }
    }

    let viewModel: TermsSummaryViewModel

    init(configuration: IdentityUIConfiguration, viewModel: TermsSummaryViewModel) {
        self.viewModel = viewModel
        super.init(configuration: configuration, navigationSettings: NavigationSettings(), trackerViewID: .termsSummary)
    }

    @IBAction func didClickClose(_: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.contentView.layer.cornerRadius = self.theme.geometry.cornerRadius
    }
}
