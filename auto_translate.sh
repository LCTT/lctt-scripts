#!/bin/bash
set -e
source base.sh

article="$*"
position="元数据"            # 其他可能值包括 "正文","引用","结尾"
while read line
do
    echo "${line}"
    if [[ "${line}" != *[a-zA-Z]* ]];then
        continue                # 至少包含一个英文字母才需要翻译
    fi
    if [[ "${position}" == "元数据" ]];then
        if [[ "${line}" == \[#\]:* ]];then
            continue
        else
            position="正文"
        fi
    fi

    if [[ "${line}" == '```' ]];then
        if [[ "${position}" != "引用" ]];then
            position="引用"
            continue
        else
            position="正文"
        fi
    fi
    
    if [[ "${line}" == "--------------------------------------------------------------------------------" ]];then
        position="结尾"
        break
    fi

    if [[ "${position}" == "正文" ]];then
        youdao.sh "${line}"
    fi
done < <(cat "${article}")
