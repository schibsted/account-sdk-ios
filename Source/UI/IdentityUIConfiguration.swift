//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Configuration to start an identity UI flow
 */
public struct IdentityUIConfiguration {
    /// The client configuration that determines your backend configuration
    public let clientConfiguration: ClientConfiguration
    ///
    public let theme: IdentityUITheme
    ///
    public let localizationBundle: Bundle
    /// The tracking event implementation that will be called at various spots in the login process
    public let tracker: TrackingEventsHandler?
    /// This determines whether you want to allow the user to dismiss the login flow
    public let isCancelable: Bool
    /// This will be given the navigationController we use internally before we start presentation incase you want to customize
    /// certain aspects
    public let presentationHook: ((UIViewController) -> Void)?
    /// This determines if you want a "skip" button to be shown which will dismiss the flow and tell you what has happened
    public let isSkippable: Bool

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
     - parameter isSkippable: If this is true then the first screen shows a skip button that produces the appropriate event
     - parameter presentationHook: Block called with the IdentityUI ViewController before it being presented.
     - parameter tracker: Required implementation of the trackinge events handler
     - parameter localizationBundle: If you have any custom localizations you want to use
     - parameter appName: If you want to customize the app name display in the UI
    */
    public init(
        clientConfiguration: ClientConfiguration,
        theme: IdentityUITheme = .default,
        isCancelable: Bool = true,
        isSkippable: Bool = false,
        presentationHook: ((UIViewController) -> Void)? = nil,
        tracker: TrackingEventsHandler? = nil,
        localizationBundle: Bundle? = nil,
        appName: String? = nil
    ) {
        self.clientConfiguration = clientConfiguration
        self.theme = theme
        self.isCancelable = isCancelable
        self.isSkippable = isSkippable
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
     - parameter isSkippable: If this is true then the first screen shows a skip button that produces the appropriate event
     - parameter presentationHook: Block called with the IdentityUI ViewController before it being presented.
     - parameter tracker: Required implementation of the trackinge events handler
     - parameter localizationBundle: If you have any custom localizations you want to use
     - parameter appName: If you want to customize the app name display in the UI
    */
    public func replacing(
        theme: IdentityUITheme? = nil,
        isCancelable: Bool? = nil,
        isSkippable: Bool? = nil,
        presentationHook: ((UIViewController) -> Void)? = nil,
        tracker: TrackingEventsHandler? = nil,
        localizationBundle: Bundle? = nil,
        appName: String? = nil
    ) -> IdentityUIConfiguration {
        return IdentityUIConfiguration(
            clientConfiguration: self.clientConfiguration,
            theme: theme ?? self.theme,
            isCancelable: isCancelable ?? self.isCancelable,
            isSkippable: isSkippable ?? self.isSkippable,
            presentationHook: presentationHook ?? self.presentationHook,
            tracker: tracker ?? self.tracker,
            localizationBundle: localizationBundle ?? self.localizationBundle,
            appName: appName ?? self.appName
        )
    }
}
