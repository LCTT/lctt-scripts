#!/bin/bash
set -e
source base.sh

cd "$(get-lctt-path)"
if ! git-branch-exist-p "LCTT";then
    git remote add LCTT https://github.com/LCTT/TranslateProject.git
fi
# 设置超时
export GIT_HTTP_LOW_SPEED_LIMIT=1000
export GIT_HTTP_LOW_SPEED_TIME=600
git fetch LCTT
git pull LCTT master:master
git push origin master:master
