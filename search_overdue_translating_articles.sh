#!/usr/bin/env bash
set -e
source $(dirname "${BASH_SOURCE[0]}")/base.sh

function help()
{
    cat <<EOF
Usage: ${0##*/} [+-rmiR} [--] 起始超期天数 [结束超期天数]

列出超期未翻译完成的文章，超期日期>=起始超期天数 同时 超期日期<结束超期天数
若结束超期天数省略，则列出 超期日期>=起始超期天数 的文章

-i 表示搜索前先初始化仓库
-r 表示自动revert翻译认领的那个提交
-m 表示发送邮件通知译者
-R 执行过程如果有错误，自动重试
EOF
}

# 初始化环境
function init_repo()
{
    # 保证处于master分支
    git checkout master
    # 拉取最新的变动
    git pull https://github.com/LCTT/TranslateProject master
    git push -u origin master
    git branch |grep -E '^  revert-'|while read branch
    do
        # 删除本地所有的revert-xxxxxxxxxxxxxxxxx分支
        git branch -D ${branch}
        # 删除remote上的revert-xxxxxxxxxxxxxxxx分支
        # 这里使用 `;:` 是为了应付remote上没有对应分支的情况，保证一定返回正确
        # TODO 也许这里不用删除，在git push时添加 -f 强制覆盖比较好？
        # git push origin :${branch};:
    done
}

while getopts :rmiR OPT; do
    case $OPT in
        i|+i)
            init_flag="True"
            ;;
        r|+r)
            revert_flag="True"
            ;;
        m|+m)
            mail_flag="True"
            ;;
        R|+R)
            trap "exec $(realpath $0) $*" ERR
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

cd $(get-lctt-path)
if [[ "${init_flag}" == "True" ]];then
    init_repo
fi

now=$(date +"%s")
timeout_start=$(($1 * 24 * 60 * 60))
timeout_end=$((${2:-9999999} * 24 * 60 * 60))
overdue_start=$((${now} - ${timeout_start}))
overdue_end=$((${now} - ${timeout_end}))
git grep -niE "translat|fanyi|翻译"  sources/*.md |awk -F ":" '{if ($2<=3) print $1}' |while read article
do
    translating_time=$(git log --date=unix --pretty=format:"%cd" -n 1 "${article}" )
    if [[ ${translating_time} -le ${overdue_start} &&  ${translating_time} -gt ${overdue_end} ]];then
        delay_days=$(( ($now - $translating_time) / 24 / 60 / 60 ))
        echo "${article}"       # "------" "${delay_days}天"
        user=$(git log --pretty='%an' -n 1 "${article}")
        email=$(git log --pretty='%ae' -n 1 "${article}")
        commit=$(git log --pretty='%H' -n 1 "${article}")
        # echo "commit is" ${commit}
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
                file_changed_count=$(git diff --name-only ${commit} ${commit}^1 |wc -l)
                if [[ ${file_changed_count} -eq 1 ]];then
                    # 若某次commit只更新一个文件，则可以直接revert这个commit
                    git revert --no-edit "${commit}"
                else
                    # 否则只能reset这个文件
                    git reset ${commit} -- "${article}"
                    git checkout "${article}"
                    git commit -a -m "超期回收: ${article}"
                fi

                git push -f -u origin "${revert_branch}"
                git checkout master
                origin_remote_user=$(git-get-remote-user origin)
                ok.sh create_pull_request "LCTT/TranslateProject" "超期回收: ${article}" "${origin_remote_user}:${revert_branch}" "master" body="@${user} 申请翻译文章${delay_days}天，因超时而撤销."
            else
                warn "${article} 选题时申请翻译已经 ${delay_days},但无法自动revert"
            fi
        fi

    fi
done
