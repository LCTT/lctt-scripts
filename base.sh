#!/bin/echo Warinng: this library should be sourced!
CFG_PATH=$(cd $(dirname "${BASH_SOURCE[0]}")&&pwd)
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
    local file="$@"
    head "$file" |grep -E -i "translat|fanyi|翻译" >/dev/null 2>&1
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

    find $(get-lctt-path) -name "*.md" -type f |grep -i "$@"
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
    echo "${url}"|sed 's#^\(https*://[^/]*\).*$#\1#'
}

function url-blocked-p()
{
    local url="$*"
    local blocked_domain=$(get-cfg-option BlockedDomains)
    local domain=$(get-domain-from-url "$url")
    # echo "$blocked_domain" |grep "$domain" >/dev/null
    [[ "${blocked_domain}" == *"${domain}"* ]] # 可以用 == 来匹配
}

function warn ()
{
    echo "$*" >&2
}

function title-to-branch ()
{
    local title="$*"
    echo "${title}"|base64 -w 0
}

function branch-to-title ()
{
    local code="$*"
    echo "${code}"|base64 -d
}

function git-get-current-branch ()
{
    git branch |grep "*" |cut -d " " -f2
}

# 根据时间以及文章title转换成标准的文件名
function date-title-to-filename()
{
    local date="$1"
    shift
    title="$*"                                     # title可能包含空格
    echo "${date} ${title}.md" |sed 's/[:~!$^]//g' # 去掉特殊字符
}

# 为文件加上翻译中的标记
function mark-file-as-tranlating()
{
    local filename="$*"
    local git_user=$(get-github-user)
    sed -i "1i translating by ${git_user}" "${filename}"
    sed -i "/-------------------------------/,$ s/译者ID/${git_user}/g" "${filename}"
}
