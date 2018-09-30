#!/bin/bash
set -e
source $(dirname "${BASH_SOURCE[0]}")/base.sh
cd $(get-lctt-path)

function help()
{
    cat <<EOF
Usage: $0 起始超期天数 [结束超期天数]

列出超期未翻译完成的文章，超期日期>=起始超期天数 同时 超期日期<=结束超期天数
若结束超期天数省略，则列出 超期日期>=起始超期天数 的文章
EOF
}

if [[ $# -eq 0 ]];then
    help
    exit 1
fi

now=$(date +"%s")
timeout_start=$(($1 * 24 * 60 * 60))
timeout_end=$((${2:-9999999} * 24 * 60 * 60))
overdue_start=$((${now} - ${timeout_start}))
overdue_end=$((${now} - ${timeout_end}))
git grep -niE "translat|fanyi|翻译"  sources/*.md |sort -t ":" -g -k 2 |grep ":1:"|cut -d : -f1 |while read article
do
    translating_time=$(git log --date=unix --pretty=format:"%cd" -n 1 "${article}" )
    if [[ ${translating_time} -le ${overdue_start} &&  ${translating_time} -ge ${overdue_end} ]];then
        delay_days=$(( ($now - $translating_time) / 24 / 60 / 60 ))
        echo "${article}"       # "------" "${delay_days}天"
    fi
done
