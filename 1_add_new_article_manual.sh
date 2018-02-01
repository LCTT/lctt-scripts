#!/bin/bash
set -e
source $(dirname "${BASH_SOURCE[0]}")/base.sh

# 获取参数
while getopts :u:t:a:d:T OPT; do
    case $OPT in
        u|+u)
            url="$OPTARG"
            ;;
        t|+t)
            title="$OPTARG"
            ;;
        d|+d)
            date="$OPTARG"
            ;;
        a|+a)
            author="$OPTARG"
            ;;
        T|+T)
            tranlate_flag="yes"
            ;;
        *)
            echo "usage: ${0##*/} [+-u url] [+-t title] [+-d date] [+-a author] [+-T]}"
            exit 2
    esac
done
shift $(( OPTIND - 1 ))
OPTIND=1

[[ -z "${url}" ]] && read -r -p "please input the URL:" url
baseurl=$(get-domain-from-url "${url}")
if url-blocked-p "${baseurl}";then
    warn "${baseurl} is blocked!"
    exit 1
fi

# 搜索类似的文章
echo "search simliar articles..."
if search-similar-articles "${url}";then
    continue-p "found similar articles"
fi

parse_url_script="parse_url_by_${0##*_}"
response=$(${CFG_PATH}/${parse_url_script} "${url}")

# 获取title
if [[ -z "${title}" ]];then
    title=$(echo ${response} |jq -r .title)
    [[ "${title}" == "null" || -z "${title}" ]] && read -r -p "please input the Title:" title
fi

# 获取date
if [[ -z "${date}" ]];then
    date=$(echo ${response} |jq -r .date_published)
    if [[ "${date}" == "null" || -z "${date}" ]];then
        read -r -p "please input the DATE(YYYYMMDD):" date
        [[ -z "${date}" ]] && date=$(date +"%Y%m%d")
    else
        date=$(echo ${date}|cut -d "T" -f1)
    fi
fi

if [[ ! "${date}" =~ [0-9]{8} ]];then
    warn "${date} is not a property date format(YYYYMMDD)"
    exit 2
fi

# 获取author
if [[ -z "${author}" ]];then
    author=$(echo ${response} |jq -r .author)
    [[ "${author}" == "null" || -z "${author}" ]] && read -r -p "please input the author:" author
fi

# 获取author link
author_link=$(get-author-link "${baseurl}" "${author}")

# 获取content
content=$(echo ${response} |jq -r .content)

echo author= "$author"
echo author_link= "${author_link}"
echo title= "${title}"
echo date_published= "${date}"
echo content= "${content}"
# echo ${response}|jq -r .content|pandoc -f html -t markdown+backtick_code_blocks-fenced_code_attributes --reference-links --reference-location=document --no-highlight
# echo ${response}|jq -r .content|html2text --reference-links --mark-code
# exit

cd "$(get-lctt-path)"
# 生成新文章
source_path="$(get-lctt-path)/sources/tech"
filename=$(date-title-to-filename "${date}" "${title}")
source_file="${source_path}"/"${filename}"

# 使用trap删掉临时文件
function cleanup_temp {
    [ -e "${source_file}" ] && rm --force "${source_file}"
    exit 0
}
trap cleanup_temp  SIGHUP SIGINT SIGPIPE SIGTERM

echo "${title}" > "${source_file}"
echo "======" >> "${source_file}"
comment="--------------------------------------------------------------------------------\\
\\
via: ${url}\\
\\
作者：[$author][a]\\
译者：[译者ID](https://github.com/译者ID)\\
校对：[校对者ID](https://github.com/校对者ID)\\
\\
本文由 [LCTT](https://github.com/LCTT/TranslateProject) 原创编译，[Linux中国](https://linux.cn/) 荣誉推出\\
\\
[a]:${author_link}"

if [[ -n "${content}" || "${content}" == "null" ]];then
    echo "${content}"|html2text  --body-width=0  --no-wrap-links --reference-links --mark-code |sed '{
s/$//;                          # 去掉
s/[[:space:]]*$//;                # 去掉每行最后的空格
/^\[code\][[:space:]]*$/,/^\[\/code\][[:space:]]*$/ s/^    //; # 去掉code block前面的空格
s/^\[\/\?code\][[:space:]]*$/```/; # 将[code]...[/code]替换成```...```
s/comic core.md Dict.md lctt2014.md lctt2016.md LCTT翻译规范.md LICENSE Makefile published README.md sign.md sources translated 选题模板.txt 中文排版指北.md/*/g; # ugly Hacked
}' >>  "${source_file}" # 将[code]...[/code] 替换成```...```

    # 算出最一个标题是多少号
    min_title=$(sed '/```/,/```/d' "${source_file}" |grep  -E "^#+ +[[:alpha:][:digit:]]" -o |awk '{print $1}'|head -1)
    echo min_title= "${min_title}"
    if [[ -n "${min_title}" ]];then
        sed -i '/```/,/```/!'"s/^${min_title}/###/" "${source_file}"
    fi


    # 找出reference links的起始位置
    reference_links_beginning_line=$(grep -nE '^   \[1\]: [^[:blank:]]' "${source_file}" |tail -n 1 |cut -d ":" -f1)
    if [[ -z ${reference_links_beginning_line} ]];then
        sed -i '$a '"${comment}" "${source_file}"
    else
        # 格式化reference links部分
        sed -i "${reference_links_beginning_line},$ {
/^[[:blank:]]*$/ d;
s/^   \(\[[[:digit:]]*\]\): /\1:/
}" "${source_file}"
        sed -i "${reference_links_beginning_line}i ${comment}" "${source_file}"
    fi
else
    sed -i '$a '"${comment}" "${source_file}"
    $(get-browser) "${url}" "http://lctt.ixiqin.com"
fi

# 添加申请翻译的标记
if [[ -n ${tranlate_flag} ]];then
    mark-file-as-tranlating "${source_file}"
fi

eval "$(get-editor) '${source_file}'"
read -p "保存好原稿了吗？按回车键继续" continue

article_type=$(guess-article-type "${source_file}")
echo article_type= "${article_type}"
article_directory="$(get-lctt-path)/sources/${article_type}"
if [[ "${article_type}" != "tech" ]];then
    mv "${source_file}" "${article_directory}"
fi
# 新建branch 并推送新文章
filename=$(basename "${source_file}")
# new_branch="add-$(title-to-branch "${filename}")"
new_branch="$(filename-to-branch add "${filename}")"
git branch "${new_branch}" master
git checkout "${new_branch}"
git add "${article_directory}/${filename}"
git commit -m "选题: ${title}" && git push -u origin "${new_branch}"
