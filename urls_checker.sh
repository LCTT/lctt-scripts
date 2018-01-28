#!/bin/bash
if [[ $# -eq 0 ]];then
    cat <<EOF
Usage:
$(basename $0) list sources/published/translated   -- 列出尚未翻译/已翻译/已发布的url
$(basename $0) comm sources/published/translated  sources/published/translated -- 检查是否有重复的urls
EOF
    exit 0
else
    operation=$1
    directory1=$2
    directory2=$3
fi

set -e
source $(dirname "${BASH_SOURCE[0]}")/base.sh
cd "$(get-lctt-path)"

function list_urls()
{
    git grep -E "^via:.+$" $1 |sed "s/^.\+via:[[:space:]]*//"|sed "s/?.\+$//"|sort
}

if [[ "${operation}" == "list" ]];then
    list_urls "${directory1}"
elif [[ "${operation}" == "comm" ]];then
    comm -12 <(list_urls "${directory1}") <(list_urls "${directory2}")
else
    warn "不支持的操作:${operation}"
fi

