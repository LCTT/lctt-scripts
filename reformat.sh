#!/bin/bash
# 使用全角中文
sed -i 's/,/，/g' "$*" # 任何,都被替换
sed -i 's/?/？/g' "$*" # 任何?都被替换

sed -i 's/!$/！/g' "$*"   # !在尾部则可被替换
sed -i 's/!\([^[]\)/！\1/g' "$*"   # !不跟[则可以被替换，但是由于图片的格式是![,因此不能被替换

# 由于.用户划分域名，因此不能被随意替换
sed -i 's/\.$/。/g' "$*"            # .在行尾也能被替换
sed -i 's/\.\([^[:upper:][:lower:]]\)/。\1/g' "$*" # .后不是英文也能被替换

# 中英文之间加上空格
sed -i 's/\([[:upper:][:lower:]]\)\([^[:upper:][:lower:][:blank:][:cntrl:][:punct:][:digit:]]\)/\1 \2/g' "$*" 
sed -i 's/\([^[:upper:][:lower:][:blank:][:cntrl:][:punct:][:digit:]]\)\([[:upper:][:lower:]]\)/\1 \2/g' "$*" 

# 中文和数字之间加上空格
sed -i 's/\([[:digit:]]\)\([^[:upper:][:lower:][:blank:][:cntrl:][:punct:][:digit:]]\)/\1 \2/g' "$*" 
sed -i 's/\([^[:upper:][:lower:][:blank:][:cntrl:][:punct:][:digit:]]\)\([[:digit:]]\)/\1 \2/g' "$*" 

# 全角标点与其他字符之间不加空格
sed -i 's/[[:blank:]]*\(，\|？\|！\|。\)/\1/' "$*"
sed -i 's/\(，\|？\|！\|。\)[[:blank:]]*/\1/' "$*"
