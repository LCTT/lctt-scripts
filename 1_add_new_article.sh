#!/bin/bash
set -e
source base.sh

# 获取参数
while getopts :u:t:d:T OPT; do
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
        T|+T)
            tranlate_flag="yes"
            ;;
        *)
            echo "usage: ${0##*/} [+-u url] [+-t title] [+-d date] [+-T]}"
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

cd "$(get-lctt-path)"

token=$(get-cfg-option Token)
response=$(curl -H "x-api-key: ${token}" "https://mercury.postlight.com/parser?url=${url}")
if [[ -z "${title}" ]];then
    title=$(echo ${response} |jq -r .title)
fi

if [[ -z "${date}" ]];then
    date=$(echo ${response} |jq -r .date_published)
    if [[ "${date}" == "null" ]];then
        date=$(date +"%Y%m%d")
    else
        date=$(echo ${date}|cut -d "T" -f1)
    fi
fi

author=$(echo ${response} |jq -r .author)
echo author= "$author",title= "${title}",date_published= "${date_published}"
# echo ${response}|jq -r .content|pandoc -f html -t markdown+backtick_code_blocks-fenced_code_attributes --reference-links --reference-location=document --no-highlight
# echo ${response}|jq -r .content|html2text --reference-links --mark-code
# exit

# 搜索类似的文章
echo "search simliar articles..."
if search-similar-articles "$title";then
    continue-p "found similar articles"
fi

# 生成新文章
source_path="$(get-lctt-path)/sources/tech"
filename=$(date-title-to-filename "${date}" "${title}")
source_file="${source_path}"/"${filename}"

echo "${title}" > "${source_file}" # 去掉title两边的双引号
echo "======" >> "${source_file}"
echo ${response}|jq -r .content|html2text --reference-links --mark-code \
    |sed '/^\[code\][[:space:]]*$/ {N;s/.*/```/}' \
    |sed '/^[[:space:]]*$/ {N;s/^[[:space:]]*\n\[\/code\][[:space:]]*$/```/}' >>  "${source_file}"
# $(get-browser) "${url}" "http://lctt.ixiqin.com"
echo "
--------------------------------------------------------------------------------

via: ${url}

作者：[$author][a]
译者：[译者ID](https://github.com/译者ID)
校对：[校对者ID](https://github.com/校对者ID)

本文由 [LCTT](https://github.com/LCTT/TranslateProject) 原创编译，[Linux中国](https://linux.cn/) 荣誉推出

[a]:${baseurl}

">>"${source_file}"

if [[ -n ${tranlate_flag} ]];then
    mark-file-as-tranlating "${source_file}"
fi
$(get-editor) "${source_file}"
read -p "保存好原稿了吗？按回车键继续" continue

# 新建branch 并推送新文章
filename=$(basename "${source_file}")
new_branch="add-$(title-to-branch "${filename}")"
git branch "${new_branch}" master
git checkout "${new_branch}"
git add "${source_file}"
git commit -m "选题: ${title}"
git push -u origin "${new_branch}"

