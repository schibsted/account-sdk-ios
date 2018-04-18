# SchibstedAccount iOS SDK

The SchibstedAccount iOS SDK provides you access to Schibsted identity services via the [SPiD](https://techdocs.spid.no/#api-reference) APIs. It provides the following:
* User management (profiles, logins, signups)
* UI based logins
* Authenticated request and oauth management

**Note: The APIs provided by the SDK do not cover the full spectrum of APIs provided by SPiD. If there is functionality missing, please look at the [SPiD API reference](https://techdocs.spid.no/#api-reference) and open up an issue for an enhancement request.**

[![Build Status](https://travis-ci.org/schibsted/account-sdk-ios.svg?branch=master)](https://travis-ci.org/schibsted/account-sdk-ios) [![license](https://img.shields.io/github/license/schibsted/account-sdk-ios.svg)](https://github.com/schibsted/account-sdk-ios/blob/master/LICENSE) [![codecov](https://codecov.io/gh/schibsted/account-sdk-ios/branch/master/graph/badge.svg)](https://codecov.io/gh/schibsted/account-sdk-ios)

- [Documentation](https://schibsted.github.io/account-sdk-ios/): Here's the documentation to the _latest tagged release_ (which can be different than the version that's in master).
- [Contributing](https://github.com/schibsted/account-sdk-ios/blob/master/CONTRIBUTING.md): For details on getting up and running if you are thinking of contributing

## Setup

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

The pod is available as a public cocoapod under the name SchibstedAccount

The SDK is divided in to different subspecs:

- `pod 'SchibstedAccount'`: this is the default and contains APIs to create a `User`
- `pod 'SchibstedAccount/Manager'`: the default installs the entire SDK. If you want to only use headless login (i.e. no UI libraries included), then just use this.

#### You may want to include a tracking subspec as well

The UI does some internal tracking, and allows a `TrackingEventsHandler` to be set in the UI's configuration.
To fulfill this, you can either implement it yourself or use one which is already implemented.

**Internal**: There is an internal Schibsted Tracking implementation for the identity SDK availabe [here](https://github.schibsted.io/spt-identity/identity-sdk-ios-tracking) and is available from `source "git@github.schibsted.io:CocoaPods/Specs.git`, so in your pod file you may:

- `pod 'SchibstedIDTracking'`: Adds dependency to the [new](https://github.schibsted.io/spt-dataanalytics/pulse-tracker-ios) pulse SDK

### [Carthage](https://github.com/Carthage/Carthage)

Add this to your `Cartfile`

```ruby
git "git@github.com:schibsted/account-sdk-ios.git"
```

Then run:
```bash
$ carthage bootstrap --platform ios
```
or
```bash
$ carthage update --platform ios
```

**Internal**: And, if you also want to include support for tracking events in the identity UI with the [new pulse SDK](https://github.schibsted.io/spt-dataanalytics/pulse-tracker-ios), add this

```ruby
git "git@github.schibsted.io:spt-identity/identity-sdk-ios-tracking"
```

Carthage will build the frameworks you need to link in your project, so make sure you follow [these steps](https://github.com/Carthage/Carthage#getting-started) to include all of them in your project and you should be up and running. If there is something missing -> [email us](mailto:support@spid.no ).

### **Get some client credentials**

The SDK works by giving you access to Schibsted users. And what kind of access is allowed is determined by a set
of client credentials. The first thing you must do is get some credentials, which can be done through
[self service](http://techdocs.spid.no/selfservice/access/). Learn about environments and merchants.

NOTE: The SDK will **not** work across environments or merchants.

## Usage

The most common use case is to get a hold of a `User` object. You can obtain a User object by using a visual or a headless login process. The visual login is the recommended approach, but if the need arises the headless approach is also documented, but not "officially" supported.

### **Set your client configuration**

See above for getting credentials. But once you have them you have to set up a `ClientConfiguration` object:

```swift
let clientConfiguration = ClientConfiguration(
        environment: .preproduction,
        clientID: "<you-client-code>",
        clientSecret: "<your-client-secret>",
        appURLScheme: nil
    )
}
```

### **Check if you already have a user**

To check if you already have a user logged in, you may use the IdentityManager:

```swift
let user = IdentityManager(clientConfiguration: clientConfiguration).currentUser
user.delegate = //...
switch user.state {
case .loggedIn:
    // Yay, carry on with app
case .loggedOut:
    // Ok, fire up the IdentityUI
}
```

### **Visual login with IdentityUI**

To start the login process you can fire up an `IdentityUI` object, configure it and it will create a `User` object for you if everything goes right. It is recommended to use the IdentityUI to create a User object because it makes sure that the correct login flows supported by the Schibsted Identity backend are adhered to (ie: required fields are filled in, and terms and conditions are accepted, etc).

#### Logging in with the IdentityUI

```swift
import UIKit
import SchibstedAccount

class ViewController: UIViewController {

    var identityUI: IdentityUI?
    var user: User?

    @IBAction func didTapLoginButton(_ sender: UIButton) {
        let identifierType: IdentifierType = (sender.tag == 0) ? .phone : .email
        self.identityUI = IdentityUI(clientConfiguration: defaultClientConfiguration, identifierType: identifierType)
        self.identityUI?.delegate = //...
        self.identityUI?.presentIdentityProcess(from: self)
    }

    @IBAction func didTapLogoutButton(_: Any) {
        self.user?.logout()
        print("User logout done!")
    }
}
```

#### IdentityUIDelegate and UserDelegate

```swift
extension ViewController: IdentityUIDelegate {
    func didFinish(result: IdentityUIResult) {
        switch result {
        case .canceled:
            print("The user canceled the login process")
        case let .completed(user):
            self.user = user
            self.user.delegate = //...
            print("User with id \(String(describing: user.id)) is logged in")
        }
    }
}
```

```swift
extension ViewController: UserDelegate {
    func user(_: User, didChangeStateTo newState: UserState) {
        switch newState {
        case .loggedIn:
            print("The user logged in")
        case .loggedOut:
            print("The user logged out")
        }
    }
}
```

#### UI Customization

The SDK includes an `IdentityUITheme` object that allows you to customize the look and feel of the identity UI. See the docs for, hopefully, more details.


#### Localization

The SDK comes with the following localization support:

1. 🇳🇴 Norwegian Bokmål
1. 🇸🇪 Swedish
1. 🇫🇮 Finnish

### **Headless login with IdentityManager**

Note: It is recommended to use the UI approach.

The `IdentityManager` is more bare bones and doesn't ensure any kind of Schibsted identity flows. It can create a user object and also notify you of any changes that happen to the user object. You can assign an `IdentityManagerDelegate` to it to handle various events that take place:

```swift
import SchibstedAccount

class ViewController: UIViewController, IdentityManagerDelegate {
    let identityManagaer = SchibstedAccount.IdentityManager(clientConfiguration: clientConfiguration)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.identityManager.delegate = self
        if self.identityManager.currentUser.state == .loggedIn {
            // User is already logged in
            return
        }

        // User not logged in
        self.login()
    }

    func userStateChanged(_ state: UserState) {
        // User has just logged in or just logged out
        if state == .LoggedIn {
            print("User with id \(String(describing: self.identityManager.currentUser.id)) is logged in")
        }
    }

    func login() {
        self.identityManager.sendCode(to: PhoneNumber(...) ...) { result in
            if case .failure(let error) = result {
                print("failed to send code", error)
            }
        }
    }

    @IBAction func validateCode(_ sender: UIButton) {
        let code = self.codeTextField.text
        identityManager.validate(oneTimeCode: code, for: PhoneNumber(...) ...) {

        }
    }
}
```

### Building, testing, documentaion

See [contributing.md](https://github.com/schibsted/account-sdk-ios/blob/master/CONTRIBUTING.md).
