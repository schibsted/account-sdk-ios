#!/usr/bin/env bash

set -e

# make sure we're in the top level directory
if [[ ! -f ".jazzy.yaml" ]]
then
    cd ".."
fi

# run jazzy
bundle exec jazzy

# make sure that everything is documented
undocumentedLineCount=$(wc -l < docs/undocumented.json)
if (( $undocumentedLineCount > 5 ))
then
    echo "ERROR: some public symbols are missing documentation comments" >&2
    cat "docs/undocumented.json" >&2
    exit 1
fi
