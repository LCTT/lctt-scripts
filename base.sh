#!/bin/echo Warinng: this library should be sourced!
CFG_PATH=$(cd $(dirname "${BASH_SOURCE[0]}")&&pwd)
# 允许直接调用第三方库
export PATH=$PATH:${CFG_PATH}/libs
function get-cfg-option ()
{
    option="$@"
    egrep "^${option}=" ${CFG_PATH}/lctt.cfg |cut -d "=" -f 2-
}
function reset-lctt-path()
{
    export LCTT=$(get-cfg-option ProjectRoot)

    if [[ -z "${LCTT}" || ! -d "${LCTT}"  ]]; then
        LCTT=$(find $HOME -iname TranslateProject 2>/dev/null |\
                   awk -F "TranslateProject"IGNORECASE=1 '{print $1}')
    fi

}

function get-lctt-path()
{
    if [[ -z ${LCTT} ]];then
        reset-lctt-path
    fi
    echo ${LCTT}
}


function file-translating-p ()
{
    local file="$*"
    head "$file" |grep -E -i "translat|fanyi|翻译" >/dev/null 2>&1
}

function file-translating-by-me-p()
{
    local file="$*"
    head "$file" |grep -E -i "translat|fanyi|翻译" |grep $(get-github-user) >/dev/null 2>&1
}

function search-similar-articles ()
{
    if [[ $# -eq 0 ]];then
        cat <<EOF
该函数可用于检查是否存在重复的文章。
Usage: $0 文件名称
EOF
        return 1
    fi

    url="$*"
    clean_url=${url%%\?*}       # 去掉URL中?后面的内容
    clean_url=${url##http*://}  # 去掉http://或https://
    echo clean_url= ${clean_url}
    # find $(get-lctt-path) -type f -name "[0-9]*.md" -print0 |xargs -I{} -0 grep -i "via:" "{}" |cut -d ":" -f2- |grep -i "${clean_url}"
    (cd $(get-lctt-path) && git grep -E "via: *https?://${clean_url}")
}

function command-exist-p()
{
    command -v "$@" >/dev/null 2>/dev/null
}

function continue-p()
{ read -p "$*,CONTINUE? [y/n]" CONT
  case $CONT in
      [nN]*)
          exit 1
          ;;
  esac
}

function get-github-user()
{
    local user=$(get-cfg-option GithubUser)
    if [[ -z ${user} ]];then
        user=$(git config --list |grep "user.name="|awk -F "=" '{print $2}')
    fi
    echo ${user}
}

function get-browser()
{
    local browser=$(get-cfg-option Browser)
    if [[ -z ${browser} ]];then
        browser="firefox"
    fi
    echo ${browser}
}

function get-editor()
{
    local editor=$(get-cfg-option Editor)
    if [[ -z ${editor} ]];then
        editor="vi"
    fi
    echo ${editor}
}

function git-branch-exist-p()
{
    local branch="$*"
    git branch -a |grep -E "${branch}" >/dev/null
}

function get-domain-from-url ()
{
    local url="$*"
    echo "${url}"|sed 's#^https*://\([^/]*\).*$#\1#'
}

function url-blocked-p()
{
    local url="$*"
    local Allowed_domain=$(get-cfg-option AllowedDomains)
    local domain=$(get-domain-from-url "$url")
    # echo "$blocked_domain" |grep "$domain" >/dev/null
    [[ "${Allowed_domain}" != *"${domain}"* ]] # 可以用 == 来匹配
}

function warn ()
{
    echo "$*" >&2
}

function git-get-current-branch ()
{
    git branch |grep "*" |cut -d " " -f2
}

function filename-to-branch ()
{
    local operation=$1
    shift
    local filename="$*"
    local code=$(echo "${filename}"|base64 -w 0)
    echo "${operation}-${code}"
}

# 解析branch中包含的操作类型 add/translate/revert
function git-branch-to-operation()
{
    local branch="$*"
    local operation=$(echo "${branch}"|cut -d "-" -f1)
    echo "${operation}"
}

# 解析branch中包含的文件名信息
function git-branch-to-filename()
{
    local branch="$*"
    local code=$(echo "${branch}" |cut -d "-" -f2)
    echo "${code}"|base64 -d
}

# 返回branch参数中正在编辑文件的 *绝对路径*
function git-branch-to-file-path()
{
    local branch="$*"
    local filename=$(git-branch-to-filename "${branch}")
    find "$(get-lctt-path)" -name "${filename}"
}

# 根据当前branch得到当前编辑的文件 *绝对路径*
function git-current-branch-to-file-path()
{
    # 在子shell中操作，不要修改原work directory
    (
    cd "$(get-lctt-path)"
    local branch=$(git-get-current-branch)
    git-branch-to-file-path "${branch}"
    )
}

# 根据时间以及文章title转换成标准的文件名
function date-title-to-filename()
{
    local date="$1"
    shift
    title=$(echo "$*" |sed 's/[^0-9a-zA-Z.,()‘_ -]/-/g'|sed 's/-*$//') # 特殊字符换成-号,最后的-去掉
    echo "${date} ${title}.md"
}

# 为文件加上翻译中的标记
function mark-file-as-tranlating()
{
    local filename="$*"
    local git_user=$(get-github-user)
    sed -i "1i translating by ${git_user}" "${filename}"
    sed -i "/-------------------------------/,$ s/译者ID/${git_user}/g" "${filename}"
}

# 根据url和author获取作者链接
function get-author-link()
{
    url="$1"
    domain=$(get-domain-from-url "${url}")
    author="$2"
    # 在子shell中操作，不要影响原shell的工作目录
    (
        cd $(get-lctt-path)
        # 选择最多的url作为author link
        git grep -iEc "via: *https*://${domain}|\[${author}\]"|grep ":2$"|cut -d":" -f1|xargs -I{} grep "\[a\]:" '{}' |sort |uniq -c |sort -n |tail -n 1 |cut -d":" -f2-
        # git grep -il "${domain}"|xargs -I{} grep -il "\[${author}\]" '{}' |tail -n 1 |xargs -I{} grep '\[a\]:' '{}' |cut -d ":" -f2-
     )
}

# 判断文件的类型是tech还是talk
function guess-article-type()
{
    local article="$*"
    if grep '```' "${article}" >/dev/null;then
        echo "tech"
    else
        echo "talk"
    fi
}

# 获取git仓库remote中的user
function git-get-remote-user()
{
    local remote="$*"
    local user_repo=$(git remote -v |grep "${remote}" |grep fetch |awk '{print $2}')
    if [[ "${user_repo}" =~ ^git@github.com: ]];then
        user_repo=${user_repo##*:}
    elif [[ "$user_repo" =~ ^https://github.com/ ]];then
        user_repo=${user_repo#https://github.com/}
    fi
    local user=${user_repo%%/*}
    echo ${user}
}

# 获取git仓库remote中的repo
function git-get-remote-repo()
{
    local remote="$*"
    local user_repo=$(git remote -v |grep "${remote}" |grep fetch |awk '{print $2}')
    if [[ "${user_repo}" =~ ^git@github.com: ]];then
        user_repo=${user_repo##*:}
    elif [[ "$user_repo" =~ ^https://github.com/ ]];then
        user_repo=${user_repo#https://github.com/}
    fi
    local repo=${user_repo#*/}
    repo=${repo%.git}
    echo ${repo}
}
