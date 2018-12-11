# Release instructions

1. Make sure all changes going in the release have been merged to `master` branch.
1. Bump the version in [Podspec](SchibstedAccount.podspec), `CFBundleShortVersionString` in `Info.plist`, and `sdkVersion` in [`Version.swift`](Source/Core/Version.swift).
1. Sanity check everything: `fastlane all`.
1. Test with the internal [Demo App](https://github.schibsted.io/spt-identity/identity-sdk-ios-tracking/)
    1. Update the version of the `SchibstedAccount` pod and re-install the pods (`./pod_install.sh`).
1. Commit above changes to a new branch, push it to GitHub, and make PR from it.
1. Wait until CI completes successfully, then merge the PR to `master`.
1. Create a new [release via GitHub](https://github.schibsted.io/spt-identity/identity-sdk-ios-tracking/releases).
    1. Enter the version number as the tag name and include the changes in the release description.
1. Publish the pod: `pod trunk push`.
1. Announce the new release on Slack in #ios-internal-libs and #spt-id-mobile.
