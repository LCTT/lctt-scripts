#! /usr/bin/env python3
import sys
import sqlite3
import feedparser


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
    if sys.argv:
        feeds = sys.argv
    else:
        feeds = ()
    for feed in feeds:
        read_feed(feed, db, db_connection)
    db_connection.close()
