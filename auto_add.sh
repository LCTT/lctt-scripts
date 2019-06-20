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

# feeds = ("https://feeds.feedburner.com/kerneltalks",  "https://www.linuxtechi.com/feed/", "https://www.datamation.com/rss.xml", "http://lukasz.langa.pl/feed/recent/rss-en.xml",  "https://feeds.feedburner.com/LinuxUprising", "https://linuxaria.com/feed", "https://dave.cheney.net/feed")

feeds="https://www.2daygeek.com/feed/ https://fedoramagazine.org/feed/  https://www.linux.com/feeds/blogs/community/rss https://itsfoss.com/feed/"

for feed in ${feeds};do
    echo "auto add ${feed}"
    ./feed_monitor.py "${feed}" |while read url
    do
        yes "
"|./1_add_new_article_manual.sh -u "${url}" -c tech  -e "echo"
        ok.sh create_pull_request "LCTT/TranslateProject" "选题: ${url}" "$(get-lctt-head)" "master"
        ./4_finish.sh -d
    done
done


# feed="https://www.networkworld.com/index.rss"
# ./feed_monitor.py "${feed}" |while read url
# do
#     yes "
# "|./1_add_new_article_manual.sh -u "${url}" -e "echo"
#     ok.sh create_pull_request "LCTT/TranslateProject" "选题: ${url}" "$(get-lctt-head)" "master"
#     ./4_finish.sh -d
# done

# feeds="https://opensource.com/feed"
# for feed in ${feeds};do
#     echo "auto add ${feed}"
#     ./feed_monitor.py "${feed}" |while read url
#     do
#         yes "
# "|./1_add_new_article_manual.sh -u "${url}"
#         ./4_finish.sh -d
#     done
# done

# feed="http://feeds.feedburner.com/Ostechnix"
# proxychains ./feed_monitor.py "${feed}" |while read url
# do
#     yes "
# "|./1_add_new_article_manual.sh -u "${url}" -c tech
#     ./4_finish.sh -d
# done

