#!/bin/bash
set -e
source $(dirname "${BASH_SOURCE[0]}")/base.sh
url="$*"
domain=$(get-domain-from-url ${url})
parse_cfg=$(jq ".\"${domain}\"" parse.json)
html=$(curl ${url})
# extract title
title_selector=$(echo ${parse_cfg}|jq -r ".title")
if [[ -z "${title_selector}" ]];then
    title_selector=".title"
fi
if [[ -n "${title_selector}" ]];then
    title=$(echo ${html}|pandoc -f html -t html -s|hxselect -c "${title_selector}"|pandoc -f html -t plain)
fi

# extract author
author_selector=$(echo ${parse_cfg}|jq -r ".author")
if [[ -n "${author_selector}" ]];then
    author=$(echo ${html}|pandoc -f html -t html -s|hxselect -c "${author_selector}"|pandoc -f html -t plain)
fi

# extract date
date_selector=$(echo ${parse_cfg}|jq -r ".date")
if [[ -n "${date_selector}" ]];then
    date=$(echo ${html}|pandoc -f html -t html -s|hxselect -c "${date_selector}"|pandoc -f html -t plain)
    date=$(date -d "${date}" "+%Y%m%d") # 格式化date
fi
# extract content
while read content_selector
do
    content_part=$(echo ${html}|pandoc -f html -t html -s|hxselect "${content_selector}")
    content="${content}
${content_part}"
done< <(echo ${parse_cfg}|jq -r ".content[]")
while read exclude_selector
do
    content=$(echo ${content}|pandoc -f html -t html -s|hxremove -i "${exclude_selector}")
done< <(echo ${parse_cfg}|jq -r ".exclude[]")
echo '{}'|jq '{"title":$title,
                "author":$author,
                "date_published":$date,
                "content":$content}' \
                    --arg title "${title}" \
                    --arg author "${author}" \
                    --arg date "${date}" \
                    --arg content "${content}"
