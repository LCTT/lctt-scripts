#!/bin/echo Warinng: this library should be sourced!
function reset-lctt-path()
{
    if [[ $# -eq 0 ]];then
        root=$HOME
    else
        root=$1
    fi

    export LCTT=$(find $root -iname TranslateProject 2>/dev/null |\
                      awk -F "TranslateProject"IGNORECASE=1 '{print $1}')
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
    head "$file" |egrep "translate|fanyi|翻译" >/dev/null 2>&1
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
