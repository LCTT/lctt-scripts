#!/bin/bash
set -e
source base.sh

cd "$(get-lctt-path)"
filepath=$(git-current-branch-to-file-path)
$(get-editor) "${filepath}"
