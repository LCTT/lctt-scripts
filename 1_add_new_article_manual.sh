#!/bin/bash
set -e
source $(dirname "${BASH_SOURCE[0]}")/base.sh

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

# 搜索类似的文章
echo "search simliar articles..."
if search-similar-articles "${url}";then
    continue-p "found similar articles"
fi

[[ -z "${title}" ]] && read -r -p "please input the Title:" title
[[ -z "${date}" ]] && read -r -p "please input the date(YYYYMMDD):" date

# 生成新文章
cd "$(get-lctt-path)"
source_path="$(get-lctt-path)/sources/tech"
filename=$(date-title-to-filename "${date}" "${title}")
source_file="${source_path}"/"${filename}"

$(get-browser) "${url}" "http://lctt.ixiqin.com"
$(get-editor) "${source_file}"

read -p "保存好原稿了吗？按回车键继续" continue
sed -i "/-------------------------------/,$ s^via: 网址^via: ${url}^" "${source_file}"
sed -i "/-------------------------------/,$ s^\[a\]:$^[a]:${baseurl}^" "${source_file}"

if [[ -n ${tranlate_flag} ]];then
    mark-file-as-tranlating "${source_file}"
fi

# 新建branch 并推送新文章
filename=$(basename "${source_file}")
# new_branch="add-$(title-to-branch "${filename}")"
new_branch="$(filename-to-branch add "${filename}")"
git branch "${new_branch}" master
git checkout "${new_branch}"
git add "${source_file}"
git commit -m "选题: ${title}"
git push -u origin "${new_branch}"
