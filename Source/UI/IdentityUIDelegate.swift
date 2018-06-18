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
    /// The process was skipped by the user
    case skipped
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

     The visual format of this error will match the built-in identity UI flow style, and instead show
     the title you specify with a description string you want.
     */
    case showError(title: String, description: String)
}

/**
 The skip disposition tells the login flow how you want to handle the user pressing the skip button
*/
public enum SkipLoginDisposition {
    /// Carry on, the flow will be dismissed
    case `continue`
    /// This will do nothing
    case ignore
}

/**
 The will-finish disposition gives you a last chance to get work done before the UI is done.
 It allows you to either continue with login or show an error screen with a message
 */
public enum LoginWillSucceedDisposition {
    /// This will carry on with the flow
    case `continue`
    /// This will show an error pop up with a title and string you specify, and restart the flow.
    case failed(title: String, message: String)
    /// This will only restart the flow without displaying any pop up message
    case restart
}

/**
 Implement this delegate to handle the events that occur inside the UI flow
 */
public protocol IdentityUIDelegate: class {
    /**
     Called when the UI flow is finished.
     */
    func didFinish(result: IdentityUIResult)

    /**
     Called before going ahead with the a flow.

     You can control whether or not you want a particular flow to be usable or not by implementing
     this method.
     */
    func willPresent(flow: LoginMethod.FlowVariant) -> LoginFlowDisposition

    /**
     This will be called when he user presses the skip button on a skippable UI flow

     You must call the done callback and tell the UI to either continue or ignore the request
     to skip the login flow

     - parameter topViewController: the view controller that is currently the topViewController of the internal naviagtion controller
     - parameter done: call this to tell the flow to continue
     */
    func skipRequested(topViewController: UIViewController, done: @escaping (SkipLoginDisposition) -> Void)

    /**
     This will be called right before `didFinish` is called with a success result

     You can use this to do other work to finish your login process. The `done` callback you call will tell the
     UI what to do next.

     The view controller passed in is whatever is being shown at the time. This can be nil in some cases where the
     login flow did not need to fire up a flow (when validating a signing deep link when launching the app for e.g.)

     - parameter result: the `User` that will be given to `didFinish`
     - parameter topViewController: The currently shown top view controller
     - parameter done: call this to say you're done so the UI can continue
     */
    func willSucceed(with user: User, on topViewController: UIViewController?, done: @escaping (LoginWillSucceedDisposition) -> Void)
}

public extension IdentityUIDelegate {
    func willPresent(flow _: LoginMethod.FlowVariant) -> LoginFlowDisposition {
        return .continue
    }

    func skipRequested(topViewController _: UIViewController, done: @escaping (SkipLoginDisposition) -> Void) {
        done(.continue)
    }

    func willSucceed(with _: User, on _: UIViewController?, done: @escaping (LoginWillSucceedDisposition) -> Void) {
        done(.continue)
    }
}
