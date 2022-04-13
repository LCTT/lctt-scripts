#!/bin/bash
set -e
source $(dirname "${BASH_SOURCE[0]}")/base.sh

# 获取参数
while getopts :u:t:a:c:d:e:Tf OPT; do
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
        e|+e)
            editor="$OPTARG"
            ;;
        a|+a)
            author="$OPTARG"
            ;;
        c|+c)
            article_type="$OPTARG"
            ;;
        T|+T)
            tranlate_flag="yes"
            ;;
        f|+f)
            force_flag="yes"    # 不检查是否在白名单内，强行选题
            ;;
        *)
            echo "usage: ${0##*/} [+-u url] [+-t title] [+-d date] [+-a author] [+-T] [+-f]}"
            exit 2
    esac
done
shift $(( OPTIND - 1 ))
OPTIND=1

[[ -z "${url}" ]] && read -r -p "please input the URL:" url
url=${url%%[?#]*}               # 清理?#后面的东西
baseurl=$(get-domain-from-url "${url}")
if [[ -z "${force_flag}" ]] && url-blocked-p "${baseurl}" ;then
    warn "${baseurl} is blocked!"
    exit 1
fi

# 搜索类似的文章
echo "search similar articles..."
if search-similar-articles "${url}";then
    continue-p "found similar articles"
fi

parse_url_script="parse_url_by_${0##*_}"
response=$(${CFG_PATH}/${parse_url_script} "${url}")

# 获取title
if [[ -z "${title}" ]];then
    title=$(echo "${response}" |jq -r .title)
    [[ "${title}" == "null" || -z "${title}" ]] && read -r -p "please input the Title:" title
fi

# 获取date
if [[ -z "${date}" ]];then
    date=$(echo "${response}" |jq -r .date_published)
    if [[ "${date}" == "null" || -z "${date}" ]];then
        read -r -p "please input the DATE(YYYYMMDD):" date
        [[ -z "${date}" ]] && date=$(date +"%Y%m%d")
    else
        date=$(echo "${date}"|cut -d "T" -f1)
    fi
fi

if [[ ! "${date}" =~ [0-9]{8} ]];then
    warn "${date} is not a property date format(YYYYMMDD)"
    exit 2
fi

# 获取author
if [[ -z "${author}" ]];then
    author=$(echo "${response}" |jq -r .author)
    [[ "${author}" == "null" || -z "${author}" ]] && read -r -p "please input the author:" author
fi

# 获取author link
author_link=$(echo "${response}" |jq -r .author_link)
if [[ "${author_link}" == "null" || -z "${author_link}" ]];then
    author_link=$(get-author-link "${url}" "${author}")
fi

# 获取summary
summary=$(echo "${response}" |jq -r .summary)

# 获取content
content=$(echo "${response}" |jq -r .content)

echo author= "$author"
echo author_link= "${author_link}"
echo title= "${title}"
echo date_published= "${date}"
echo content= "${content}"

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

cat > "${source_file}" <<EOF
[#]: subject: "${title}"
[#]: via: "${url}"
[#]: author: "$author ${author_link}"
[#]: collector: "$(get-github-user)"
[#]: translator: " "
[#]: reviewer: " "
[#]: publisher: " "
[#]: url: " "

${title}
======
${summary}
EOF
comment="--------------------------------------------------------------------------------\\
\\
via: ${url}\\
\\
作者：[$author][a]\\
选题：[$(get-github-user)][b]\\
译者：[译者ID](https://github.com/译者ID)\\
校对：[校对者ID](https://github.com/校对者ID)\\
\\
本文由 [LCTT](https://github.com/LCTT/TranslateProject) 原创编译，[Linux中国](https://linux.cn/) 荣誉推出\\
\\
[a]: ${author_link}\\
[b]: https://github.com/$(get-github-user)"

if [[ -n "${content}" && "${content}" != "null" ]];then
    echo "${content}"|pandoc --reference-links --reference-location=document -f html-native_divs-native_spans -t gfm+backtick_code_blocks+fenced_code_blocks-shortcut_reference_links+markdown_attribute --wrap=preserve --strip-comments --no-highlight --indented-code-classes=python|pandoc -f gfm -t html-native_divs-native_spans |html2text  --body-width=0  --no-wrap-links --reference-links --mark-code |sed '{
s/$//;                          # 去掉
s/[[:space:]]*$//;                # 去掉每行最后的空格
# /^\[code\]/,/^\[\/code\]/ s/^    //; # 去掉code block前面的空格
# 将[code]...[/code]替换成```...```
s/^\[code\]/\n```\n/; # 将[code]替换成\n```\n,在代码块的三个“`” 之外和段落之间需要额外加个空行，当段落和它连在一起时，在一些 md 编辑器里面是识别有问题的（MacDown）。
s/^\[\/code\][[:space:]]*$/```/; # [/code]替换成```
s/\[\/code\][[:space:]]*$/\n```/; # [/code]替换成```
s/&lt;/</g; # 把 &lt; 替换成 <
s/&gt;/>/g; # 把 &gt; 替换成 >
}'|${CFG_PATH}/format_source_block.awk >>  "${source_file}" # 将[code]...[/code] 替换成```...```

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
s/^   \(\[[[:digit:]]*\]\):/\1:/
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

if [[ -z "${editor}" ]];then
    editor="$(get-editor)"
fi

eval "${editor} '${source_file}'"

if [[ -z "${article_type}" ]];then
    read -p "保存好原稿后请输入文章的类型(tech/talk),直接按回车表示由系统自动判断" article_type
fi

if [[ -z "${article_type}" ]];then
    article_type=$(guess-article-type "${source_file}")
fi

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
git commit -m "选题[${article_type}]: ${date} ${title}

sources/${article_type}/${filename}" && git push -u origin "${new_branch}"
