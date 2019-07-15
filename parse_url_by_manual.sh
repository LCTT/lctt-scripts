#!/bin/bash
set -e
source $(dirname "${BASH_SOURCE[0]}")/base.sh
url="$*"
domain=$(get-domain-from-url ${url})
parse_cfg=$(jq ".\"${domain}\"" parse.json)

function html_cleanup()
{
    cleanup_command=$(echo "${parse_cfg}"|jq -r ".cleanup_command")
    if [[ "${cleanup_command}" == "null" ]];then
        tidy -q --force-output yes --drop-empty-elements no --drop-empty-paras no --indent no |pandoc -t html -f html
    else
        eval "${cleanup_command}"
    fi
    return 0
}
TMPFILE=$(mktemp)
trap "rm -f ${TMPFILE}" EXIT
wget --header "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:65.0) Gecko/20100101 Firefox/65.0" --convert-links -O ${TMPFILE} ${url}
html="$(cat ${TMPFILE}|html_cleanup)"
# echo ${html}>/tmp/t.html
# extract title
title_selector=$(echo "${parse_cfg}"|jq -r ".title")
if [[ "${title_selector}" == "null" ]];then
    title_selector=".title"
fi
if [[ "${title_selector}" != "null" ]];then
    title=$(echo "${html}"|hxselect -c "${title_selector}"|pandoc -f html -t plain  --wrap=none) # 标题中可能包含换行符，修改成空格
fi

# extract author
author_selector=$(echo "${parse_cfg}"|jq -r ".author")
if [[ "${author_selector}" != "null" ]];then
    author=$(echo "${html}"|hxselect -c "${author_selector}"|pandoc -f html -t plain  --wrap=none|sed 's/ *([^()]\+)//g') # author中不能带括号,把括号内的内容删掉
fi

# extract authorlink
authorlink_selector=$(echo "${parse_cfg}"|jq -r ".authorlink")
if [[ "${authorlink_selector}" != "null" ]];then
    authorlink=$(echo "${html}"|hxselect -c "${authorlink_selector}"|pandoc -f html -t plain  --wrap=none)
    if [[ -n "${authorlink}" ]];then
        authorlink=$(get-abstract-url "${url}" "${authorlink}")
    fi
fi

# extract summary
summary_selector=$(echo "${parse_cfg}"|jq -r ".summary")
if [[ "${summary_selector}" != "null" ]];then
    summary=$(echo "${html}"|hxselect -c "${summary_selector}"|pandoc -f html -t plain)
fi

# extract date
date_selector=$(echo "${parse_cfg}"|jq -r ".date")
if [[ "${date_selector}" != "null" ]];then
    echo "${html}">/tmp/t.html
    date=$(echo "${html}"|hxselect -c "${date_selector}"|pandoc -f html -t plain)
    if [[ -n "${date}" ]];then
        date=${date%%T*}                    # 格式化年月日T时分秒这种格式，特点是以T分割
        date=$(date -d "${date}" "+%Y%m%d") # 格式化date
    fi
fi
# extract content
while read exclude_selector
do
    html=$(echo "${html}"|hxremove -i "${exclude_selector}")
done< <(echo ${parse_cfg}|jq -r ".exclude[]")
while read content_selector
do
    content_part=$(echo "${html}"|hxselect "${content_selector}")
    content="${content}
${content_part}"
done< <(echo "${parse_cfg}"|jq -r ".content[]")
echo '{}'|jq '{"title":$title,
                "author":$author,
                "author_link":$authorlink,
                "summary":$summary,
                "date_published":$date,
                "content":$content}' \
                    --arg title "${title}" \
                    --arg author "${author}" \
                    --arg authorlink "${authorlink}" \
                    --arg summary "${summary}" \
                    --arg date "${date}" \
                    --arg content "${content}"
