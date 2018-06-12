//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import SafariServices
import UIKit

protocol FlowCoordinator: class {
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
        self.value = coordinator as AnyObject
        coordinator.start(input: input, completion: completion)
    }

    func handle(route: IdentityUI.Route) -> RouteHandlerResult {
        return (self.value as? RouteHandler)?.handle(route: route) ?? .cannotHandle
    }
}

extension FlowCoordinator {
    func spawnChild<F: FlowCoordinator>(_ coordinator: F, input: F.Input, completion: @escaping (F.Output) -> Void) {
        self.child = ChildFlowCoordinator(coordinator, input: input) { [weak self] output in
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
        if let presentedViewController = self.navigationController.presentedViewController {
            return presentedViewController as? IdentityUIViewController
        }
        return self.navigationController.topViewController as? IdentityUIViewController
    }

    func presentAsPopup(_ viewController: UIViewController) {
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.modalTransitionStyle = .crossDissolve
        self.navigationController.topViewController?.present(viewController, animated: true, completion: nil)
    }

    func present(error: ClientError) {
        let strings = ErrorScreenStrings(localizationBundle: self.configuration.localizationBundle)
        let viewController = ErrorViewController(configuration: self.configuration, error: error, from: self.presentedViewController, strings: strings)
        self.presentAsPopup(viewController)
    }

    func presentInfo(title: String, text: String, titleImage: UIImage? = nil) {
        let viewController = InfoViewController(
            configuration: self.configuration,
            title: title,
            text: text,
            titleImage: titleImage
        )
        self.presentAsPopup(viewController)
    }

    func presentError(title: String, description: String) {
        let strings = ErrorScreenStrings(localizationBundle: self.configuration.localizationBundle)
        let viewController = ErrorViewController(
            configuration: self.configuration,
            customText: (title, description),
            from: self.presentedViewController,
            strings: strings
        )
        self.presentAsPopup(viewController)
    }

    func present(url: URL) {
        let viewController = SafariViewController(url: url)
        viewController.modalTransitionStyle = .coverVertical
        if #available(iOS 10.0, *) {
            viewController.preferredControlTintColor = self.configuration.theme.colors.iconTint
        }
        self.navigationController.present(viewController, animated: true, completion: nil)
    }

    func isPresentingURL(containing path: String) -> Bool {
        guard let safariViewController = self.navigationController.visibleViewController as? SafariViewController else {
            return false
        }
        return safariViewController.url.absoluteString.contains(path)
    }

    func dismissURLPresenting() {
        guard self.navigationController.visibleViewController is SafariViewController else {
            return
        }
        self.navigationController.dismiss(animated: true, completion: nil)
    }
}

class SafariViewController: SFSafariViewController {
    let url: URL

    init(url: URL) {
        self.url = url
        super.init(url: url, entersReaderIfAvailable: false)
    }
}
