# Contributing to the code

## Prerequisites

1. Install Xcode: the easiest is to install it as a [free app from the Mac AppStore](https://itunes.apple.com/us/app/xcode/id497799835?mt=12).
1. Clone the [repo](github.com/schibsted/account-sdk-ios).
1. Install required development tools:
    If you want to install all the tools at once, get [Bundler](https://bundler.io/) and then install with:

        bundler install

    this will install everything with known working versions from the [Gemfile](https://github.com/schibsted/account-sdk-ios/blob/master/Gemfile), including [CocoaPods](https://cocoapods.org/).

    **Note**: Installing a ruby version manager such as [RVM](https://rvm.io) will make life a little easier

### Getting Example app to build

You will not be able to compile the Example app out of the box without doing one of the following:

**Core Developer**:

We use blackbox for secrets. The Example app uses configuration files that are only available to active developers of the SDK. To use the example app out of the box, you will need to ask for permission to be added to the blackbox admins.
    1. Go [here](https://github.com/StackExchange/blackbox) and follow installation instructions.
    1. [Add yourself](https://github.com/StackExchange/blackbox#how-to-indoctrinate-a-new-user-into-the-system) and push a PR.
    1. Wait till an admin re-encrypts files with your credentials and merges your PR.

**Other Developer**

To get the Example app to compile if you are not a core developer, you need to run the [populate dummy secrets](https://github.com/schibsted/account-sdk-ios/blob/master/scripts/populate-dummy-secrets.sh) script before anything else:

    ./scripts/populate-dummy-secrets.sh

The Example app will then build and there's an offline mode switch (experimental) to see various functionality in action, but you will not be able to make real requests to Schibsted's backend without getting some client credentials. The [README](https://github.com/schibsted/account-sdk-ios/blob/master/README.md) containts details on how to get credentials.

**Building**:

Open up SchibstedAccount.xcodeproj and hack away.

## Code style

We try to keep the code base consistent and we have a number of checks in place but also rely on each other to maintain consistency across the code base. It's recommended to familiarize yourself with the Swift community practices found [here](https://swift.org/documentation/api-design-guidelines/). If you are looking for a source of inspiration then the Swiftified Foundation classes and the Swift standard libraries should be your go to references.

**Linting**: The CI will also run the changes through `swiftlint` from the project directory. You can install [Swiftlint](https://github.com/realm/SwiftLint) with Homebrew if you have it or they have an installer as well - "SwiftLint.pkg".

**Formatting**: The CI will also make sure swiftformat has been run. You can install [Swiftformat](https://github.com/nicklockwood/SwiftFormat) with Homebrew as well, or check the site for other optionas.

**Editorconfig**: There is also an [editorconfig](https://github.com/schibsted/account-sdk-ios/blob/master/.editorconfig) file that ensures a few consistencies if your editor has [editorconfig support](http://editorconfig.org/#download).

## Pre-commit hooks and CI

**NOTE** The CI will fail if the commands in the pre commit hooks produce errors.

There are some git pre-commit hooks you should use that could possibly save you from failing CI builds because of forgetting to fix a silly lint error for eg. There is also a install script provided to set them up in your repo. Run the following form your root to set it up

  scripts/setup-git-hooks.sh

## Commit messages

For automation purposes, please try to structure your commit messages in the following way:
```
<COMMIT_TYPE>: <COMMIT_DESCRIPTION>
```
Where `<COMMIT_TYPE>` is one of:
* **Added** - If the commit adds new features or functionality.
* **Changed** - If the commit changes some existing functionality.
* **Deprecated** - If the commit deprecates some functionality.
* **Removed** - If the commit removes some previously deprecated functionality.
* **Fixed** - If the commit fixes some bugs or issues.
* **Security** - If the commit introduces security fixes, which should be highlighted separately to
encourage users to update.

For example:
* `Added: Adds APIs for UI passwordless sign-in.`
* `Changed: Api constructors now take a Configuration instead of a String.`
* `Deprecated: Manager.init() overloads with overly large amounts of parameters have been
deprecated. Use the overloads which take Options objects instead.`
* `Removed: Removed deprecated Manager.init(...) overloads.`
* `Fixed: Fixes a bug where client tokens would not be refreshed correctly.`
* `Security: Fixes a concern where user credentials were vulnerable to attacks based on redirects.`

## **Running the tests**

In Xcode: run the tests using &#8984;U (Product - Test). Make sure that the "Example" scheme is selected.

With fastlane it's just `fastlane test` from your command line.

If you did not install via bundler, you can install [Fastlane](https://github.com/fastlane/fastlane) manually (if gem install fastlane doesn't work then "Installer Script" approach might work better with a default macOS Ruby without RVM).

If you make a pull request github, a Travis CI bot will run the tests for you.

### **Documentation**

Install [jazzy](https://github.com/realm/jazzy), run jazzy, profit (if you installed via bundler then you already have it):

```bash
gem install jazzy
jazzy
open docs/index.html
```

Documentation is updated and deployed whenever there is a tagged commit.
