#!/usr/bin/env bash

set -e

bundlePrefix=Schibsted
scriptName=$(basename "$0")

ls -1 $HOME/Library/Logs/DiagnosticReports/$bundlePrefix*.crash 2> /dev/null | while read logFileName
do
    echo "$scriptName: start of file $logFileName"
    cat "$logFileName"
    echo "$scriptName: end of file $logFileName"
done
