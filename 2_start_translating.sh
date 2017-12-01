#!/bin/bash
set -e
source base.sh
declare -a files

if [[ $# -eq 0 ]];then
    i=0
    while read -r file;do
        if ! file-translating-p "${file}";then
           printf "%3d. %s\n" $i "${file}"
           files[$i]="${file}"
           i=$((i+1))
        fi
    done< <(find "$(get-lctt-path)"/sources -name "2*.md")
    read -r -p "input the article number you want to translate: " num
    file="${files[$num]}"
else
    file="$*"
fi

if file-translating-p "${file}";then
    echo "${file} is under translating!" >&2
    exit 1
fi

cd "$(dirname "${file}")"
filename=$(basename "${file}")
git_user=$(get-github-user)
new_branch=$(echo "translating-${filename}"|sed 's/ /_/g')
git branch "${new_branch}"
git checkout "${new_branch}"
sed -i "1i translating by ${git_user}" "${filename}"
git add "${filename}"
git commit -m "translating by ${git_user}"
git push -u origin "${new_branch}"
