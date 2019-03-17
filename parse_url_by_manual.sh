#!/bin/bash
set -e
source $(dirname "${BASH_SOURCE[0]}")/base.sh
url="$*"
domain=$(get-domain-from-url ${url})
parse_cfg=$(jq ".\"${domain}\"" parse.json)
# extract title
title_selector=$(echo ${parse_cfg}|jq -r ".title")
if [[ -z "${title_selector}" ]];then
    title_selector=".title"
fi
title=$(echo ${html}|hxclean|hxselect -c "${title_selector}"|pandoc -f html -t plain)
# extract author
author_selector=$(echo ${parse_cfg}|jq -r ".author")
author=$(echo ${html}|hxclean|hxselect -c "${author_selector}"|pandoc -f html -t plain)
# extract date
date_selector=$(echo ${parse_cfg}|jq -r ".date")
date=$(echo ${html}|hxclean|hxselect -c "${date_selector}"|pandoc -f html -t plain)
date=$(date -d "${date}" "+%Y%m%d") # 格式化date
# extract content
while read content_selector
do
    content_part=$(echo ${html}|hxclean|hxselect "${content_selector}")
    content="${content}
${content_part}"
done< <(echo ${parse_cfg}|jq -r ".content[]")
while read exclude_selector
do
    content=$(echo ${content}|hxclean|hxremove -i "${exclude_selector}")
done< <(echo ${parse_cfg}|jq -r ".content[]")
echo '{}'|jq '{"title":$title,
                "author":$author,
                "date_published":$date,
                "content":$content}' \
                    --arg title "${title}" \
                    --arg author "${author}" \
                    --arg date "${date}" \
                    --arg content "${content}"
