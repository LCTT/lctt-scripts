#!/bin/bash
set -e
source base.sh
# 搜索可以翻译的文件
declare -a files
sources_dir="$(get-lctt-path)"/sources
if [[ $# -eq 0 ]];then
    i=0
    while read -r file;do
        if ! file-translating-p "${file}" ;then
           printf " %3d. %s\n" $i "${file}"
           files[$i]="${file}"
           i=$((i+1))
        elif file-translating-by-me-p "${file}";then
            printf "*%3d. %s\n" $i "${file}"
            files[$i]="${file}"
            i=$((i+1))
        fi
    done< <(find "${sources_dir}" -name "2*.md"|sort)
    read -r -p "input the article number you want to translate: " num
    file="${source_dir}"/"${files[$num]}" # 使用绝对路径，否则后面无法cd进入文件所在目录
else
    file="$*"
fi


cd "$(dirname "${file}")"
filename=$(basename "${file}")
# new_branch="translate-$(title-to-branch "${filename}")"
new_branch="$(filename-to-branch translate "${filename}")"
git branch "${new_branch}" master
git checkout "${new_branch}"
# 如果没有翻译，则加上翻译标志
if ! file-translating-p "${filename}";then
    mark-file-as-tranlating  "${filename}"
fi
git add "${filename}"
git_user=$(get-github-user)
git commit -m "translating by ${git_user}"
git push -u origin "${new_branch}"

# 打开要翻译的文章
$(get-editor) "${file}"
