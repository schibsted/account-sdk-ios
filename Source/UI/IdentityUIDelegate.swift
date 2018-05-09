//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/// The result of calling `IdentityUI.presentIdentityProcess(from viewController:)
public enum IdentityUIResult {
    /// The process conpleted successfully and you have a valid `User` object
    case completed(User)
    /// The process was cancelled by the user
    case canceled
    /// There was an error during the UI process before there was a UI to display
    case failed(Error)
}

/**
 The flow dispositions can tell the login flow what to do right before it is about to go to a
 login or signup flow.
 */
public enum LoginFlowDisposition {
    /// Just carry on
    case `continue`
    /// Do not carry on, and either dismiss or do not dismiss the flow
    case abort(shouldDismiss: Bool)
    /**
     Do not carry on, show a popup error instead

     The visual format of this error will match the build-in identity UI flow style, and instead show
     the title you specify with a description string you want.
     */
    case showError(title: String, description: String)
}

/**
 Implement this delegate to handle the events that occur inside the UI flow
 */
public protocol IdentityUIDelegate: class {
    /**
     Called when either the UI flow is done, or cancelled
     */
    func didFinish(result: IdentityUIResult)
    /**
     Called before going ahead with the a flow.

     You can control whether or not you want a particular flow to be usable or not by implementing
     this method.
     */
    func willPresent(flow: LoginMethod.FlowVariant) -> LoginFlowDisposition
}

public extension IdentityUIDelegate {
    func willPresent(flow _: LoginMethod.FlowVariant) -> LoginFlowDisposition {
        return .continue
    }
}
