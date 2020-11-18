#!/usr/bin/env bash

set -e

# make sure we're in the top level directory
if [[ ! -f ".jazzy.yaml" ]]
then
    cd ".."
fi

# run jazzy
bundle exec jazzy
