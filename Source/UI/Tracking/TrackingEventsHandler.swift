//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Used by some internal objects to handle tracking data

 There are multiple implementation of TrackingEventsHandler that have different
 dependencies. So you can include the one which matches your depdendency and then
 pass that along to the objects that require tracking
 */
public protocol TrackingEventsHandler: class {
    /// Will be set by IdentityUI on UI initialization
    var clientConfiguration: ClientConfiguration? { get set }
    /// Will be set by IdentityUI on UI initialization
    var loginMethod: LoginMethod? { get set }
    /// Does the user want to login or create an account
    var loginFlowVariant: LoginMethod.FlowVariant? { get set }
    /// Users loginID if available
    var loginID: String? { get set }

    /// Track view event
    func view(_ view: TrackingEvent.View)
    /// Track engagement event
    func engagement(_ engagement: TrackingEvent.Engagement)
    /// Track error event
    func error(_ type: TrackingEvent.ErrorType, in view: TrackingEvent.View)
}

///
public enum TrackingEvent {
    /// View events are typically broadcast on viewDidLoad or before a view is presented.
    public enum View {
        /// Screen to enter identifier for password login method was viewed
        case passwordIdentificationForm
        /// Screen to enter identifier for passwordless login method was viewed
        case passwordlessIdentificationForm
        /// Screen to enter password was viewed
        case passwordInput
        /// Screen to verify passworldess identifier was viewed
        case passwordlessInput
        /// Screen to resend password was viewed
        case passwordlessResend
        /// Terms and conditions screen was viewed
        case terms
        /// Terms and conditions summary was viewed
        case termsSummary
        /// Information screen to check email for verification link is shown
        case accountVerification
        /// Screen to enter required fields is shown
        case requiredFieldsForm
        /// Error popup screen was shown
        case error
    }

    /// Engagement events are the result of user interaction
    public enum Engagement {
        /// A click event in a screen
        case click(EngagementType, TrackingEvent.View)
        /// A networking event as a result of a user action
        case network(NetworkType)
        /// Different type of click events
        public enum EngagementType {
            /// Typically when a form is submitted
            case submit
            /// When terms and conditions are accepted
            case accept
            /// Close event
            case close
            /// Resent identifier click
            case resend
            /// Request to change identifier
            case changeIdentifier
            /// Request for help
            case help
            /// Request to see the summary of terms and conditions update
            case agreementsSummary
            /// Request to see platform terms and conditions
            case agreementsSPiD
            /// Request to see client terms and conditions
            case agreementsClient
            /// Request to see platform privacy policy
            case privacySPiD
            /// Request to see client privacy policy
            case privacyClient
            /// Request to go to forgot password flow
            case forgotPassword
        }
        /// The network events that can result from user interaction
        public enum NetworkType {
            /// Identity flow completed
            case done
            /// Verification code send
            case verificationCodeSent
            /// Agreements accepted
            case agreementAccepted
            /// Required fields registered
            case requiredFieldProvided
            /// Account verified due to deep link
            case accountVerified
        }
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
}
