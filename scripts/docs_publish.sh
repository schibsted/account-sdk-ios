#!/usr/bin/env bash

# $1 - docs directory name on the github pages site
#      defaults to "master", but also can be a tag name like "0.10.0"

set -e

# get the tag
if [[ -z "$1" ]]
then
    tag=master
else
    tag="$1"
fi

# get the docs_dir
if [[ -d docs ]]
then
    docs_dir=docs
elif [[ -d ../docs ]]
then
    docs_dir=../docs
else
    echo "ERROR: docs_dir is not found, run jazzy first" >&2
    exit 1
fi

checkout_dir=$(mktemp -d -t docs_publish_checkout)
remote_url=$(git remote get-url origin)

# checkout
git clone "$remote_url" "$checkout_dir"
git -C "$checkout_dir" checkout gh-pages

# sync
target_dir="$checkout_dir/docs/$tag"
mkdir -p "$target_dir"
rsync --recursive --delete --exclude=docsets --delete-excluded "$docs_dir/" "$target_dir"

# commit
git -C "$checkout_dir" add docs
if git -C "$checkout_dir" diff-index --quiet --cached HEAD
then
    echo "no changes to the documentation detected, skipping the push"
else
    git -C "$checkout_dir" commit -m "update docs for $tag"
    git -C "$checkout_dir" push
fi

# cleanup
rm -rf "$checkout_dir"
