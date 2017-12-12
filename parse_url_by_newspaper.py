import sys
import datetime
import json
from newspaper import Article
url = sys.argv[1]

article = Article(url, keep_article_html=True)
article.download()
article.parse()

authors = ';'.join(article.authors)
title = article.title
date = article.publish_date
if not date:
    date = datetime.datetime.now()
date = date.strftime('%Y%m%d')

html_content = article.article_html
content = article.text

data = {"title": title,
        "date_published": date,
        "content": html_content,
        "author": authors}

print(json.dumps(data))
