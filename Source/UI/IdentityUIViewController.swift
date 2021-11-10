//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

private class IdentityUIBarButtonItem: UIBarButtonItem {
    private var actionHandler: (() -> Void)?

    convenience init(title: String?, style: UIBarButtonItem.Style, action: (() -> Void)?) {
        self.init(title: title, style: style, target: nil, action: nil)
        target = self
        self.action = #selector(barButtonItemPressed(sender:))
        actionHandler = action
    }

    @objc func barButtonItemPressed(sender _: UIBarButtonItem) {
        actionHandler?()
    }
}

struct NavigationSettings {
    typealias Action = () -> Void

    let cancel: Action?
    let navigateBack: Action?

    init(cancel: Action? = nil, back: Action? = nil) {
        self.cancel = cancel
        navigateBack = back
    }
}

class IdentityUIViewController: UIViewController {
    class var nibName: String? {
        return String(describing: self)
    }

    let configuration: IdentityUIConfiguration
    let navigationSettings: NavigationSettings

    var theme: IdentityUITheme {
        return configuration.theme
    }

    @IBOutlet var scrollView: UIScrollView!
    var viewToEnsureVisibilityOfAfterKeyboardAppearance: UIView?

    private var leftAlignNavigationTitle = false

    init(configuration: IdentityUIConfiguration,
         navigationSettings: NavigationSettings,
         trackerScreenID: TrackingEvent.Screen,
         trackerViewAdditionalFields: [TrackingEvent.AdditionalField] = []) {
        self.configuration = configuration
        self.navigationSettings = navigationSettings
        self.trackerScreenID = trackerScreenID
        self.trackerViewAdditionalFields = trackerViewAdditionalFields
        let typeSelf = type(of: self)
        #if SWIFT_PACKAGE
            let bundle = Bundle.module
        #else
            let bundle = Bundle(for: typeSelf)
        #endif
        super.init(nibName: typeSelf.nibName, bundle: bundle)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var navigationTitle: String {
        return ""
    }

    let trackerScreenID: TrackingEvent.Screen
    let trackerViewAdditionalFields: [TrackingEvent.AdditionalField]

    private func applyThemeToView(_ view: UIView) {
        (view as? Themeable)?.applyTheme(theme: theme)
        for subview in view.subviews {
            applyThemeToView(subview)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        applyThemeToView(view)

        var leftBarButtonItems: [UIBarButtonItem] = []

        if let backAction = navigationSettings.navigateBack {
            let backBarButtonItem = IdentityUIBarButtonItem(
                title: nil,
                style: .plain,
                action: backAction
            )
            backBarButtonItem.image = theme.icons.navigateBack
            backBarButtonItem.tintColor = theme.colors.iconTint

            leftBarButtonItems.append(backBarButtonItem)
        } else {
            navigationItem.leftBarButtonItem = nil
        }

        if leftAlignNavigationTitle {
            let titleLabel = UILabel()
            titleLabel.text = navigationTitle
            titleLabel.font = configuration.theme.fonts.title
            titleLabel.sizeToFit()
            let titleBarButtonItem = UIBarButtonItem(customView: titleLabel)
            leftBarButtonItems.append(titleBarButtonItem)
            title = nil
        } else {
            title = navigationTitle
        }
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItems = leftBarButtonItems

        if let cancelAction = navigationSettings.cancel {
            let barButtonItem = IdentityUIBarButtonItem(
                title: nil,
                style: .plain,
                action: cancelAction
            )
            barButtonItem.image = theme.icons.cancelNavigation
            barButtonItem.tintColor = theme.colors.iconTint
            navigationItem.rightBarButtonItem = barButtonItem
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        if #available(iOS 13.0, *) {
            isModalInPresentation = !configuration.isCancelable
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configuration.tracker?.interaction(.view, with: trackerScreenID, additionalFields: trackerViewAdditionalFields)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(false)
    }

    @objc private func keyboardDidShow(notification: NSNotification) {
        guard let view = viewToEnsureVisibilityOfAfterKeyboardAppearance else {
            return
        }

        guard let scrollView = scrollView else {
            assertionFailure(
                "Attempt to set viewToEnsureVisibilityOfAfterKeyboardAppearance without a scroll view: "
                    + "did you forget to set the scrollView outlet?"
            )
            return
        }

        guard let endFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        let keyboardMinY = self.view.convert(endFrame, from: nil).minY
        let bottomPadding: CGFloat = 8
        let viewMaxY = self.view.convert(view.frame, from: view.superview).maxY + bottomPadding
        let delta = keyboardMinY - viewMaxY

        if delta > 0 {
            return
        }

        var contentOffset = scrollView.contentOffset
        contentOffset.y -= delta
        scrollView.setContentOffset(contentOffset, animated: true)
    }

    func startLoading() {
        // This ensures the keyboard is dismissed before the view interaction is disabled
        // which is necessary for the keyboard appearance notifications to be correctly delivered.
        view.endEditing(true)
        view.isUserInteractionEnabled = false
    }

    func endLoading() {
        view.isUserInteractionEnabled = true
    }

    @discardableResult func showInlineError(_: ClientError) -> Bool {
        return false
    }
}
