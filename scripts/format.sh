#!/usr/bin/env bash

if [[ -z "${TRAVIS}" ]]; then
    swiftformat Source/ Example/ \
        --exclude Example/Pods/ \
        --comments ignore \
        --ranges nospace \
        --insertlines disabled \
        --self insert \
        --header "\
\n\
 Copyright 2011 - 2018 Schibsted Products & Technology AS.\n\
 Licensed under the terms of the MIT license. See LICENSE in the project root.\n\
"
fi
