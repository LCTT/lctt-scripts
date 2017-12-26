#!/bin/bash
source base.sh
while getopts :dm: OPT; do
    case $OPT in
        d|+d)
            delete_branch=1
            ;;
        m|+m)
            commit_message="$OPTARG"
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
if [[ "${current_branch}" == "master" ]];then
    warn "Project is under the master branch! Exiting"
    exit 1
fi

operation=$(git-branch-to-operation "${current_branch}")
filename=$(git-branch-to-filename "${current_branch}")
reformat_flag=$(get-cfg-option AutoReformat)
sources_file_path=$(find ./ -name "${filename}") # 搜索出相对路径

if [[ -n "${reformat_flag}" && "${reformat_flag}" != "0" ]];then
    echo "reformat the ${sources_file_path}"
    $CFG_PATH/reformat.sh "${sources_file_path}"
fi

if [[ "${operation}" == "translate" && "${sources_file_path}" =~ ^\./sources/.+$ ]];then
    translated_file_path="$(echo "${sources_file_path}"|sed 's/sources/translated/')"
    echo git mv "${sources_file_path}" "${translated_file_path}"
    git mv "${sources_file_path}" "${translated_file_path}"
fi

if [[ -z "${commit_message}" ]];then
    commit_message="${operation} done at $(date)"
fi

git add .
git commit -m "${commit_message}"
git push -u origin "${current_branch}"
git checkout master
if [[ -n "${delete_branch}" ]];then
    git branch -d "${current_branch}"
fi
