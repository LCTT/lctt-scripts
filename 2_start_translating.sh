#!/bin/bash
set -e
source base.sh

file="$1"
if file-translating-p ${file};then
    echo "${file} is under translating!" >&2
    exit 1
fi

cd $(dirname "${file}")
filename=$(basename "${file}")
git_user=$(get-github-user)
new_branch=$(echo "translating-${filename}"|sed 's/ /_/g')
git branch "${new_branch}"
git checkout "${new_branch}"
sed -i "1i translating by ${git_user}" "${filename}"
git add "${filename}"
git commit -m "translating by ${git_user}"
git push -u origin "${new_branch}"
