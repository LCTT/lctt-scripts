#! /usr/bin/env python3
import sys
import sqlite3
import feedparser

# feedparser.USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/116.0"

def is_article_exist(url, db):
    '''检查URL是否已经在DB中存在'''
    db.execute("SELECT 1 from rss where url=?", (url,))
    return db.fetchall()


def add_new_article(url, db, db_connection):
    '''将URL加入到DB中'''
    db.execute("INSERT INTO rss values(?)", (url,))
    db_connection.commit()


def read_feed(feed, db, db_connection):
    feed = feedparser.parse(feed)
    for article in feed['entries']:
        url = article['link']
        if not is_article_exist(url, db):
            print(url)
            add_new_article(url, db, db_connection)


if __name__ == '__main__':
    path = ".rss_db.sqlite"
    db_connection = sqlite3.connect(path)
    db = db_connection.cursor()
    db.execute('CREATE TABLE IF NOT EXISTS rss(url TEXT)')
    if len(sys.argv) > 1:
        feeds = sys.argv[1:]
    else:
        feeds = ("http://feeds.feedburner.com/Ostechnix", "https://opensource.com/feed", "https://www.2daygeek.com/feed/", "https://fedoramagazine.org/feed/", "https://www.networkworld.com/index.rss", "https://feeds.feedburner.com/kerneltalks", "https://www.linux.com/feeds/blogs/community/rss", "https://www.linuxtechi.com/feed/", "https://www.datamation.com/rss.xml", "http://lukasz.langa.pl/feed/recent/rss-en.xml", "https://itsfoss.com/feed/", "https://feeds.feedburner.com/LinuxUprising", "https://linuxaria.com/feed", "https://dave.cheney.net/feed")
    for feed in feeds:
        read_feed(feed, db, db_connection)
    db_connection.close()
