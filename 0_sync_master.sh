#!/bin/bash
set -e
source base.sh

cd "$(get-lctt-path)"
if ! git-branch-exist-p "LCTT";then
    git remote add LCTT https://github.com/LCTT/TranslateProject.git
fi

git fetch LCTT
git pull LCTT master:master
