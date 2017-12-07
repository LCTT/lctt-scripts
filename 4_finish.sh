#!/bin/bash
source base.sh
while getopts :d OPT; do
    case $OPT in
        d|+d)
            delete_branch=1
            ;;
        *)
            echo "usage: ${0##*/} [+-d}"
            exit 2
    esac
done
shift $(( OPTIND - 1 ))
OPTIND=1

cd $(get-lctt-path)
git add .
git commit -m "update at $(date)"
current_branch=$(git-get-current-branch)
git push -u origin "${current_branch}"
git checkout master
if [[ -n "${delete_branch}" ]];then
    git branch -d "${current_branch}"
fi
