fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios test
```
fastlane ios test
```
Runs all the tests

- `COVERAGE`: To coverage or not to doc (default to NO)
### ios lint
```
fastlane ios lint
```
Lint the source code and other linteable artifacts
### ios documentation
```
fastlane ios documentation
```
Generate documentation for the source code
### ios all
```
fastlane ios all
```
Execute all lanes

Configurable with:

- `LINT`: To lint or not to lint (default to YES)

- `TESTS`: To test or not to test (default to YES)

- `DOCUMENTATION`: To doc or not to doc (default to YES)
### ios clean
```
fastlane ios clean
```
clean derived data

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
