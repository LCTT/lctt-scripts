#!/bin/bash
set -e
source $(dirname "${BASH_SOURCE[0]}")/base.sh
cd $(get-lctt-path)

function help()
{
    cat <<EOF
Usage: ${0##*/} [+-rm} [--] 起始超期天数 [结束超期天数]

列出超期未翻译完成的文章，超期日期>=起始超期天数 同时 超期日期<结束超期天数
若结束超期天数省略，则列出 超期日期>=起始超期天数 的文章

-r 表示自动revert翻译认领的那个提交
-m 表示发送邮件通知译者
EOF
}

while getopts :rm OPT; do
    case $OPT in
        r|+r)
            revert_flag="True"
            ;;
        m|+m)
            mail_flag="True"
            ;;
        *)
            help
            exit 2
    esac
done
shift $(( OPTIND - 1 ))
OPTIND=1

if [[ $# -eq 0 ]];then
    help
    exit 2
fi

now=$(date +"%s")
timeout_start=$(($1 * 24 * 60 * 60))
timeout_end=$((${2:-9999999} * 24 * 60 * 60))
overdue_start=$((${now} - ${timeout_start}))
overdue_end=$((${now} - ${timeout_end}))
git grep -niE "translat|fanyi|翻译"  sources/*.md |sort -t ":" -g -k 2 |grep ":1:"|cut -d : -f1 |while read article
do
    translating_time=$(git log --date=unix --pretty=format:"%cd" -n 1 "${article}" )
    if [[ ${translating_time} -le ${overdue_start} &&  ${translating_time} -gt ${overdue_end} ]];then
        delay_days=$(( ($now - $translating_time) / 24 / 60 / 60 ))
        echo "${article}"       # "------" "${delay_days}天"
        user=$(git log --pretty='%an' -n 1 "${article}")
        email=$(git log --pretty='%ae' -n 1 "${article}")
        commit=$(git log --pretty='%H' -n 1 "${article}")
        if [[ ${mail_flag} == "True" ]];then
            title="您申请翻译${article}已经有${delay_days}天"
            mail -s "${title}" ${email}<<EOF
亲爱的${user},您好:

    您申请翻译 ${article} 已经 ${delay_days} 天了。
    感谢您的热心参与，但若太久时间没有结果我们将自动回收您的翻译申请，请悉知。

--------------------------------------------------------------------

顺祝时祺，
Linux中国
EOF
        fi

        if [[ ${revert_flag} == "True" ]];then
            commit_times=$(git log --pretty='%H' -n 2 "${article}"|wc -l)
            # 排除选题时就申请翻译的情况，这种情况无法revert,否则选题就没了
            if [[ ${commit_times} -gt 1 ]];then
                revert_branch=$(filename-to-branch "revert" "${article}")
                git branch "${revert_branch}" master
                git checkout "${revert_branch}"
                git revert --no-edit "${commit}"
                git push -u origin "${revert_branch}"
                git checkout master
                origin_remote_user=$(git-get-remote-user origin)
                ok.sh create_pull_request "LCTT/TranslateProject" "auto revert ${article}" "${origin_remote_user}:${revert_branch}" "master"
            else
                warn "${article} 选题时申请翻译已经 ${delay_days},但无法自动revert"
            fi
        fi

    fi
done
