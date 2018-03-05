#!/usr/bin/env bash

set -e

root="$1"
newname="$2"
task="IDMOB-37"

if [[ ! -d "$root" ]]
then
    echo "The SDK directory is not found."
    exit 1
fi

if [[ -z "$newname" ]]
then
    echo "Specify the new name."
    exit 2
fi

# the name of the podspec file is the name of the SDK
oldname=$(basename -s .podspec "$root"/*.podspec)

# rename files
git -C "$root" clean -dfx
while [[ -n $(find "$root" -name "*$oldname*") ]]
do
    find "$root" -name "*$oldname*" | head -1 \
        | ruby -n -e "i = \$_.rindex('$oldname'); r = \$_.dup; r[i ... i + '$oldname'.length] = '$newname'; print 'git -C \"$root\" mv ', \$_.chomp, ' ', r.chomp" | bash
done

git -C "$root" commit -m "$task rename files from $oldname to $newname"

# rename file contents
git -C "$root" grep --name-only "$oldname" | sed "s#^#$root/#" | xargs -L 1 sed -i '' "s/$oldname/$newname/g"
git -C "$root" add .
git -C "$root" commit -m "$task replace text $oldname to $newname"
