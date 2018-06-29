#!/usr/bin/env bash

brew update

brew outdated swiftlint || brew upgrade swiftlint
brew install swiftformat

swiftlint version
swiftformat --version
