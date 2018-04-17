//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Configuration to start an identity UI flow
 */
public struct IdentityUIConfiguration {
    ///
    public let clientConfiguration: ClientConfiguration
    ///
    public let theme: IdentityUITheme
    ///
    public let localizationBundle: Bundle
    ///
    public let tracker: TrackingEventsHandler?
    ///
    public let isCancelable: Bool
    ///
    public let presentationHook: ((UIViewController) -> Void)?

    private var _appName: String?

    /**
     Some of the UI screens will use the bundle name of your app. Sometimes this is not what you want
     so you can set this to override it
     */
    public var appName: String {
        get {
            guard let name = self._appName else {
                // Try and set from bundle name
                guard let name = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String else {
                    preconditionFailure("Could not fetch bundle name. Please set IdentityUIConfiguration.appName")
                }
                return name
            }
            return name
        }
        set {
            self._appName = newValue
        }
    }

    /**
     - parameter clientConfiguration: the `ClientConfiguration` object
     - parameter theme: The `IdentityUITheme` object
     - parameter isCancelable: If this is false then the user cannot cancel the UI flow unless you complete it
     - parameter presentationHook: Block called with the IdentityUI ViewController before it being presented.
     - parameter tracker: Required implementation of the trackinge events handler
     - parameter localizationBundle: If you have any custom localizations you want to use
     - parameter appName: If you want to customize the app name display in the UI
    */
    public init(
        clientConfiguration: ClientConfiguration,
        theme: IdentityUITheme = .default,
        isCancelable: Bool = true,
        presentationHook: ((UIViewController) -> Void)? = nil,
        tracker: TrackingEventsHandler? = nil,
        localizationBundle: Bundle? = nil,
        appName: String? = nil
    ) {
        self.clientConfiguration = clientConfiguration
        self.theme = theme
        self.isCancelable = isCancelable
        self.presentationHook = presentationHook
        self.localizationBundle = localizationBundle ?? IdentityUI.bundle
        self.tracker = tracker
        if let appName = appName {
            self.appName = appName
        }
    }

    /**
     Call this to replace "parts" of the configuration

     - parameter theme: The `IdentityUITheme` object
     - parameter isCancelable: If this is false then the user cannot cancel the UI flow unless you complete it
     - parameter presentationHook: Block called with the IdentityUI ViewController before it being presented.
     - parameter tracker: Required implementation of the trackinge events handler
     - parameter localizationBundle: If you have any custom localizations you want to use
     - parameter appName: If you want to customize the app name display in the UI
    */
    public func replacing(
        theme: IdentityUITheme? = nil,
        isCancelable: Bool? = nil,
        presentationHook: ((UIViewController) -> Void)? = nil,
        tracker: TrackingEventsHandler? = nil,
        localizationBundle: Bundle? = nil,
        appName: String? = nil
    ) -> IdentityUIConfiguration {
        return IdentityUIConfiguration(
            clientConfiguration: self.clientConfiguration,
            theme: theme ?? self.theme,
            isCancelable: isCancelable ?? self.isCancelable,
            presentationHook: presentationHook ?? self.presentationHook,
            tracker: tracker ?? self.tracker,
            localizationBundle: localizationBundle ?? self.localizationBundle,
            appName: appName ?? self.appName
        )
    }
}
