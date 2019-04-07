#!/bin/env bash
#feed="https://fedoramagazine.org/feed/"
feed="$1"
./feed_monitor.py "${feed}" |while read url
do
yes n |./1_add_new_article_manual.sh -u "${url}" -c tech
done
