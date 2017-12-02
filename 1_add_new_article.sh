#!/bin/bash
set -e
source base.sh

read -r -p "please input the URL:" url
baseurl=$(get-domain-from-url "${url}")
if url-blocked-p "${baseurl}";then
    warn "${baseurl} is blocked!"
    exit 1
fi

read -r -p "please input the Title:" title
read -r -p "please input the date(YYYYMMDD):" date

echo "search simliar articles..."
if search-similar-articles "$title";then
    continue-p "found similar articles"
fi

cd "$(get-lctt-path)"
git checkout master
source_path="$(get-lctt-path)/sources/tech"
source_file="${source_path}/${date} ${title}.md"

$(get-browser) "${url}" "http://lctt.ixiqin.com"
$(get-editor) "${source_file}"

read -p "保存好原稿了吗？按回车键继续" continue
sed -i "/-------------------------------/,$ s#via: 网址#via: ${url}#" "${source_file}"
sed -i "/-------------------------------/,$ s#\[a\]:#[a]:${baseurl}#" "${source_file}"

new_branch=$(echo "add-${title}"|sed 's/ /_/g')
echo "${new_branch}"
git branch "${new_branch}" master
git checkout "${new_branch}"
git add "${source_file}"
git commit -m "选题: ${title}"
git push -u origin "${new_branch}"
