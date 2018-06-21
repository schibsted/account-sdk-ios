//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 The TrackingEventsHandler can inform of certain events. These are sent
 through this delegate
*/
public protocol TrackingEventsHandlerDelegate: class {
    /**
      Should be called when a new JWE is returned

      This is used by the `IdentityUI` to link tracking events between
      the SDK and the SPiD backend
     */
    func trackingEventsHandlerDidReceivedJWE(_ jwe: String)
}

/**
 Used by some internal objects to handle tracking data

 There are multiple implementation of TrackingEventsHandler that have different
 dependencies. So you can include the one which matches your depdendency and then
 pass that along to the objects that require tracking
 */
public protocol TrackingEventsHandler: class {
    /// This is used by the IdentityUI to know when there's some extra information available for it to use
    var delegate: TrackingEventsHandlerDelegate? { get set }
    /// Will be set by IdentityUI on UI initialization
    var clientConfiguration: ClientConfiguration? { get set }
    /// Will be set by IdentityUI on UI initialization
    var loginMethod: LoginMethod? { get set }
    /// Does the user want to login or create an account, set by IdentityUI
    var loginFlowVariant: LoginMethod.FlowVariant? { get set }
    /// Users loginID if available, set by IdentityUI
    var loginID: String? { get set }
    /// The merchant ID for the host app
    var merchantID: String? { get set }

    /// A screen was viewed
    func view(_ screen: TrackingEvent.Screen)
    /// An element in the UI was interacted with on some scree
    func engagement(_ engagement: TrackingEvent.Engagement, in screen: TrackingEvent.Screen)
    /// An error occured on some screen
    func error(_ type: TrackingEvent.ErrorType, in screen: TrackingEvent.Screen)
}

///
public enum TrackingEvent {
    /// Represent the different screens that a user can be viewing
    public enum Screen {
        /// Screen to enter identifier for password login method was viewed
        case passwordIdentificationForm(additionalFields: [AdditionalField])
        /// Screen to enter identifier for passwordless login method was viewed
        case passwordlessIdentificationForm(additionalFields: [AdditionalField])
        /// Screen to enter password was viewed
        case passwordInput
        /// Screen to verify passworldess identifier was viewed
        case passwordlessInput
        /// Terms and conditions screen was viewed
        case terms
        /// Information screen to check email for verification link is shown
        case accountVerification
        /// Screen to enter required fields is shown
        case requiredFieldsForm
        /// A popup screen
        case popup(Popup)

        /// The various popup screens
        public enum Popup {
            /// The informational popup screen
            case info
            /// The error popup screen
            case error
            /// The resend code popup screen
            case resend
        }
    }

    /// Represent the different elements on forms that can be interacted with
    public enum UIElement {
        /// A submit button was clicked and it might have some additional info
        case submit(with: [AdditionalField])
        /// Request to change identifier
        case changeIdentifier
        /// Request to see platform terms and conditions
        case agreementsSchibstedAccount
        /// Request to see client terms and conditions
        case agreementsClient
        /// Request to see platform privacy policy
        case privacySchibstedAccount
        /// Request to see client privacy policy
        case privacyClient
        /// Resent identifier click
        case resend
        /// Request to go to forgot password flow
        case forgotPassword
        /// Request to see info about Schibsted Account
        case whatsSchibstedAccount
        /// Request to see info about "Remember me on this device" feature
        case rememberMeInfo
        /// Request to see info about adjusting privacy choices
        case adjustPrivacyChoices
        /// Request to see info about Schibsted
        case learnMoreAboutSchibsted
    }

    /// Engagement events are the result of user interaction
    public enum Engagement {
        /// Represents a click engagement event on an element in the forms
        case click(on: UIElement)
    }

    /// Different error events
    public enum ErrorType {
        /// Input validation error
        case validation(ClientError)
        /// Networking error
        case network(ClientError)
        /// Unknown error
        case generic(Error)
    }

    /// Supplementary fields that may be added to some event types as the need arises
    public enum AdditionalField {
        /// Whether the user selected to keep the login status persistent
        case keepLoggedIn(Bool)
        /// if there's a teaser or not
        case teaser(Bool)
    }
}
