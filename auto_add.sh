#!/bin/env bash
source $(dirname "${BASH_SOURCE[0]}")/base.sh

function get-lctt-head()
{
    (
        cd $(get-lctt-path)
        local remote_user=$(git-get-remote-user origin)
        local current_branch=$(git-get-current-branch)
        echo "${remote_user}:${current_branch}"
    )
}

function get-lctt-last-commit-title()
{
    (
        cd $(get-lctt-path)
        git log -1 --format="format:自动%s"|head -n 1
    )
}

function get-lctt-operation-file()
{
    (
        cd $(get-lctt-path)
        local current_branch=$(git-get-current-branch)
        git-branch-to-file-path "${current_branch}"
    )
}

function is-valid-file()
{
    (
        cd $(get-lctt-path)
        local operation_file="$*"
        local file_size=$(cat "${operation_file}"|wc -w)
        # 文件字数达到500字才认为是有效文章
        [[ ${file_size} -gt 500 ]] && grep '^\[#\]: author: ' "${operation_file}" |grep "http"
    )
}

function auto-pull-request()
{
    local added_file=$(get-lctt-operation-file)
    if is-valid-file "${added_file}";then
        echo "${added_file} 文件是有效文件，自动提交"
        ok.sh create_pull_request "LCTT/TranslateProject" "$(get-lctt-last-commit-title)" "$(get-lctt-head)" "master"
    else
        echo "${added_file} 文件不是有效文件，不自动提交"
    fi
}
# feeds = ("https://feeds.feedburner.com/kerneltalks", "https://www.datamation.com/rss.xml", "http://lukasz.langa.pl/feed/recent/rss-en.xml",  "https://feeds.feedburner.com/LinuxUprising", "https://linuxaria.com/feed", )

# tech类别
feeds="https://www.2daygeek.com/feed/ https://fedoramagazine.org/feed/  https://www.linux.com/feeds/blogs/community/rss https://itsfoss.com/feed/ https://www.linuxtechi.com/feed/ https://dave.cheney.net/feed https://jvns.ca/atom.xml https://www.jtolio.com/rss.xml"

for feed in ${feeds};do
    echo "auto add ${feed}"
    ./feed_monitor.py "${feed}" |while read url
    do
        yes "
"|./1_add_new_article_manual.sh -u "${url}" -c tech  -e "echo"
        auto-pull-request
        ./4_finish.sh -d
    done
done

# 自判断类别
feeds="https://www.networkworld.com/index.rss https://opensourceforu.com/feed"
for feed in ${feeds};do
    ./feed_monitor.py "${feed}" |while read url
    do
        yes "
"|./1_add_new_article_manual.sh -u "${url}" -e "echo"
        auto-pull-request
        ./4_finish.sh -d
    done
done

# feed="http://feeds.feedburner.com/Ostechnix"
# proxychains ./feed_monitor.py "${feed}" |while read url
# do
#     yes "
# "|./1_add_new_article_manual.sh -u "${url}" -c tech
#     ./4_finish.sh -d
# done

# talk 类别
feeds="https://twobithistory.org/feed.xml"
for feed in ${feeds};do
    ./feed_monitor.py "${feed}" |while read url
    do
        yes "
"|./1_add_new_article_manual.sh -u "${url}" -e "echo" -c talk -a 'Two-Bit History'
        auto-pull-request
        ./4_finish.sh -d
    done
done

# 手工指定作者
./feed_monitor.py "https://theartofmachinery.com/feed.xml" |while read url
do
    yes "
"|./1_add_new_article_manual.sh -u "${url}" -e "echo" -a 'Simon Arneaud'
    auto-pull-request
    ./4_finish.sh -d
done
