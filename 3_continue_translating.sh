#!/bin/bash
set -e
source base.sh

cd "$(get-lctt-path)"
branch=$(git-get-current-branch)
echo "$branch"
code=$(echo "$branch" |cut -d "-" -f2)
filename=$(branch-to-title "${code}")
filepath=$(find "$(get-lctt-path)" -name "${filename}")
$(get-editor) "${filepath}"
