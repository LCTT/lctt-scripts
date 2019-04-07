#!/bin/env bash
# feeds = ("http://feeds.feedburner.com/Ostechnix", "https://opensource.com/feed", "https://www.2daygeek.com/feed/", "https://fedoramagazine.org/feed/", "https://www.networkworld.com/index.rss", "https://feeds.feedburner.com/kerneltalks", "https://www.linux.com/feeds/blogs/community/rss", "https://www.linuxtechi.com/feed/", "https://www.datamation.com/rss.xml", "http://lukasz.langa.pl/feed/recent/rss-en.xml", "https://itsfoss.com/feed/", "https://feeds.feedburner.com/LinuxUprising", "https://linuxaria.com/feed", "https://dave.cheney.net/feed")
# feeds = ("https://www.2daygeek.com/feed/", "https://fedoramagazine.org/feed/", "https://www.networkworld.com/index.rss", "https://www.linux.com/feeds/blogs/community/rss", "https://itsfoss.com/feed/")
feed="$1"
./feed_monitor.py "${feed}" |while read url
do
yes n |./1_add_new_article_manual.sh -u "${url}" -c tech
./4_finish.sh -d
done
