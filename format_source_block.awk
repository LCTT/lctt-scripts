#! /usr/bin/awk -f
BEGIN{
    IGNORECASE=1;
    # LINT=1;
    source_block_syntax_start="```"
    source_block_syntax_end="```"
}

function min(n,m)
{
    if (n<m){
        return n;
    }
    return m;
}

function is_blank(content)
{
    return content ~ "^[[:blank:]]*$"
}

function rtrim(content)
{
    # match(content, "[[:space:]]*$")
    # return substr(content,)
    sub("[[:space:]]*$", "", content)
    return content
}

# _ARGVEND_ 后面的参数是用来定义局部变量的，不做真正的参数用，详情请参见[[https://www.ibm.com/developerworks/cn/linux/l-cn-awkf/index.html]]
function collect_src_block(_ARGVEND_, src_block, src_lines,idx,i,min_blank_num)
{
    idx = 0;
    min_blank_num = 1000;
    # 跳过代码快中最开始的空行
    getline
    while(is_blank($0)){
        getline
    }
    while($0 !~ source_block_syntax_end){
        src_lines[idx] = $0;
        idx++;
        if(! is_blank($0)){ # skip blank lines
            match($0,"^ *");        # We should only delete the space, since the TAB is import in the makefile
            min_blank_num = min(RLENGTH,min_blank_num);
        }
        getline;
    }

    for(i=0; i<idx; i++)
    {
        src_block = src_block substr(src_lines[i], min_blank_num+1) ORS;
    }
    return rtrim(src_block);
}


{
    if(match($0, source_block_syntax_start)){
        print $0;
        print collect_src_block();
        print $0;
    }
    else
    {
        print $0;
    }
}
