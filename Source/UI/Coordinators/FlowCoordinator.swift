//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import SafariServices
import UIKit

protocol FlowCoordinator: AnyObject {
    associatedtype Output
    associatedtype Input

    var child: ChildFlowCoordinator? { get set }

    var navigationController: UINavigationController { get }
    var configuration: IdentityUIConfiguration { get }

    func start(input: Input, completion: @escaping (Output) -> Void)
}

// Type erasure to be able to hold a child coordinator property.
class ChildFlowCoordinator: RouteHandler {
    private let value: AnyObject

    init<F: FlowCoordinator>(_ coordinator: F, input: F.Input, completion: @escaping (F.Output) -> Void) {
        value = coordinator as AnyObject
        coordinator.start(input: input, completion: completion)
    }

    func handle(route: IdentityUI.Route) -> RouteHandlerResult {
        return (value as? RouteHandler)?.handle(route: route) ?? .cannotHandle
    }
}

extension FlowCoordinator {
    func spawnChild<F: FlowCoordinator>(_ coordinator: F, input: F.Input, completion: @escaping (F.Output) -> Void) {
        child = ChildFlowCoordinator(coordinator, input: input) { [weak self] output in
            self?.child = nil
            completion(output)
        }
    }
}

enum RouteHandlerResult {
    case handled
    case resetRequest
    case cannotHandle
}

protocol RouteHandler {
    func handle(route: IdentityUI.Route) -> RouteHandlerResult
}

extension FlowCoordinator {
    var presentedViewController: IdentityUIViewController? {
        if let presentedViewController = navigationController.presentedViewController {
            return presentedViewController as? IdentityUIViewController
        }
        return navigationController.topViewController as? IdentityUIViewController
    }

    func presentAsPopup(_ viewController: UIViewController) {
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.modalTransitionStyle = .crossDissolve
        navigationController.topViewController?.present(viewController, animated: true, completion: nil)
    }

    func present(error: ClientError) {
        let strings = ErrorScreenStrings(localizationBundle: configuration.localizationBundle)
        let viewController = ErrorViewController(configuration: configuration, error: error, from: presentedViewController, strings: strings)
        presentAsPopup(viewController)
    }

    func presentInfo(title: String, text: String, titleImage: UIImage? = nil) {
        let viewController = InfoViewController(
            configuration: configuration,
            title: title,
            text: text,
            titleImage: titleImage
        )
        presentAsPopup(viewController)
    }

    func presentError(title: String? = nil, description: String, completion: (() -> Void)? = nil) {
        let strings = ErrorScreenStrings(localizationBundle: configuration.localizationBundle)
        let viewController = ErrorViewController(
            configuration: configuration,
            customText: (title, description),
            from: presentedViewController,
            strings: strings
        )
        viewController.didRequestAction = { action in
            switch action {
            case .dismiss:
                completion?()
            }
        }
        presentAsPopup(viewController)
    }

    func present(url: URL) {
        let viewController = SafariViewController(url: url)
        viewController.modalTransitionStyle = .coverVertical
        viewController.modalPresentationStyle = .overFullScreen
        if #available(iOS 10.0, *) {
            viewController.preferredControlTintColor = self.configuration.theme.colors.iconTint
            viewController.preferredBarTintColor = self.configuration.theme.colors.barTintColor
        }
        navigationController.present(viewController, animated: true, completion: nil)
    }

    func isPresentingURL(containing path: String) -> Bool {
        guard let safariViewController = navigationController.visibleViewController as? SafariViewController else {
            return false
        }
        return safariViewController.url.absoluteString.contains(path)
    }

    func dismissURLPresenting() {
        guard navigationController.visibleViewController is SafariViewController else {
            return
        }
        navigationController.dismiss(animated: true, completion: nil)
    }
}

class SafariViewController: SFSafariViewController {
    let url: URL

    init(url: URL) {
        self.url = url
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        super.init(url: url, configuration: configuration)
    }
}
