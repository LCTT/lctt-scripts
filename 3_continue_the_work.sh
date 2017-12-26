#!/bin/bash
set -e
source base.sh

cd "$(get-lctt-path)"
current_branch=$(git-get-current-branch)
if [[ "$current_branch" == "master" ]];then
    i=0
    while read branch;do
        operation=$(git-branch-to-operation "${branch}")
        filename=$(git-branch-to-filename "${branch}")
        printf "%3d. %10s %s\n" $i "${operation}" "${filename}"
        branches[$i]=$branch
        i=$((i+1))
    done < <(git branch |grep -v 'master')
    echo "YOU ARE UNDER BRANCH MASTER"
    read -r -p "Which branch do you want to checkout(input the id): " num
    echo git checkout "${branches[$i]}"
    git checkout "${branches[$num]}"
fi

filepath=$(git-current-branch-to-file-path)
$(get-editor) "${filepath}"
