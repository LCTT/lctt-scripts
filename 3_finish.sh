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
current_branch=$(git-get-current-branch)
operation=$(git-branch-to-operation "${current_branch}")
if [[ "${operation}" == "translate" ]];then
    filename=$(git-branch-to-filename "${current_branch}")
    sources_file_path=$(find ./ -name "${filename}") # 搜索出相对路径
    if [[ "${sources_file_path}" =~ ^\./sources/.+$ ]];then
        translated_file_path="$(echo "${sources_file_path}"|sed 's/sources/translated/')"
        echo git mv "${sources_file_path}" "${translated_file_path}"
        git mv "${sources_file_path}" "${translated_file_path}"
    fi
fi

git add .
git commit -m "update at $(date)"
git push -u origin "${current_branch}"
git checkout master
if [[ -n "${delete_branch}" ]];then
    git branch -d "${current_branch}"
fi
