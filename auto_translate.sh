#!/bin/bash
set -e
source base.sh

article="$*"
position="元数据"            # 其他可能值包括 "正文","引用","结尾"
while read line
do
    echo "${line}"
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
        continue
    fi

    if [[ "${position}" == "正文"  && "${line}" == *[a-zA-Z]* ]];then
        youdao.sh "${line}" # 至少包含一个英文字母才需要翻译
    fi
done < <(cat "${article}")
