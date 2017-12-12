#!/bin/bash
# 使用全角中文
source base.sh
if [[ $# -eq 0 ]];then
    cd "$(get-lctt-path)"
    filepath=$(git-current-branch-to-file-path)
else
    filepath="$*"
fi

sed -i '1,/----------------------------------------------------------------/ {
s/,/，/g;                       # 任何,都被替换
s/?/？/g;                       # 任何?都被替换
s/!$/！/g;                      # !在尾部则可被替换
s/!\([^[]\)/！\1/g;             # !不跟[则可以被替换，但是由于图片的格式是![,因此不能被替换
# 由于.用户划分域名，因此不能被随意替换
s/\.$/。/g;                     # .在行尾也能被替换
s/\.\([^[:upper:][:lower:][:digit:]]\)/。\1/g; # .后不是英文也能被替换
# 中英文之间加上空格
s/\([[:upper:][:lower:]]\)\([^[:upper:][:lower:][:blank:][:cntrl:][:punct:][:digit:]]\)/\1 \2/g;
s/\([^[:upper:][:lower:][:blank:][:cntrl:][:punct:][:digit:]]\)\([[:upper:][:lower:]]\)/\1 \2/g;
# 中文和数字之间加上空格
s/\([[:digit:]]\)\([^[:upper:][:lower:][:blank:][:cntrl:][:punct:][:digit:]]\)/\1 \2/g;
s/\([^[:upper:][:lower:][:blank:][:cntrl:][:punct:][:digit:]]\)\([[:digit:]]\)/\1 \2/g;
# 全角标点与其他字符之间不加空格
s/[[:blank:]]*\(，\|？\|！\|。\)/\1/;
s/\(，\|？\|！\|。\)[[:blank:]]*/\1/
}' "${filepath}"
