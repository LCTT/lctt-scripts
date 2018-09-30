#!/bin/bash
set -e
source $(dirname "${BASH_SOURCE[0]}")/base.sh
cd $(get-lctt-path)

timeout=${1:-30}
timeout=$(($timeout * 24 * 60 * 60))
now=$(date +"%s")
overdue=$((${now} - ${timeout}))
git grep -niE "translat|fanyi|翻译"  sources/*.md |sort -t ":" -g -k 2 |grep ":1:"|cut -d : -f1 |while read article
do
    last_modify_time=$(git log --date=unix --pretty=format:"%cd" -n 1 "${article}" )
    if [[ ${last_modify_time} -lt ${overdue} ]];then
        echo "${article}"
    fi
done
