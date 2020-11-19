#!/usr/bin/env bash

set -e

copyright="\
\n\
Copyright 2011 - `date +'%Y'` Schibsted Products & Technology AS.\n\
Licensed under the terms of the MIT license. See LICENSE in the project root.\n\
"
common_args=("Source/" "Example/"
        "--ranges" "nospace"
        "--disable" "blankLinesBetweenScopes,initCoderUnavailable,redundantReturn,redundantSelf,redundantType,wrapMultilineStatementBraces"
        "--header" "$copyright")

if [[ -z "${TRAVIS}" ]]; then
    swiftformat "${common_args[@]}"
else
    swiftformat --dryrun "${common_args[@]}" > swiftformat_result
    linecount=$(wc -l < swiftformat_result)
    if (( $linecount > 2 ))
    then
        echo "ERROR: a number of files had incorrrect formatting. Please run swiftformat
on each of your commits. Alternatively, install the provided githook to do it for you.
See the CONTRIBUTING.md file for more details: " >&2
        cat "swiftformat_result" >&2
        exit 1
    fi
fi
