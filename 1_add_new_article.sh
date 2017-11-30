#!/bin/bash
set -e
source base.sh
read -p "please input the Title:" title
read -p "please input the URL:" url
read -p "please input the date(YYYYMMDD):" date

echo "search simliar articles..."
if search-similar-articles "$title";then
    continue-p "found similar articles"
fi

cd $(get-lctt-path)
source_path=$(get-lctt-path)/sources/tech
source_file=${source_path}/${date}\ ${title}.md
html2text --protect-links --decode-errors=ignore "$url" > "${source_file}" || \
    pandoc -t markdown "$url" |egrep -v "^:::" > "${source_file}" 

echo "
--------------------------------------------------------------------------------

via: ${url}

作者：[ ][a]
译者：[译者ID](https://github.com/译者ID)
校对：[校对者ID](https://github.com/校对者ID)

本文由 [LCTT](https://github.com/LCTT/TranslateProject) 原创编译，[Linux中国](https://linux.cn/) 荣誉推出
" >> "${source_file}"

new_branch=$(echo "add-${title}"|sed 's/ /_/g')
echo $new_branch
git branch "${new_branch}"
git checkout "${new_branch}"
git add "${source_file}"
git commit -m "选题: ${title}"
git push -u origin "${new_branch}"
