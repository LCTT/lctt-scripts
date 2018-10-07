#!/usr/bin/env bash

cd ~
# 添加邮件通知的SMTP信息
if [[ ! -f ~/.mailrc ]];then
    echo 下面录入邮件通知的SMTP信息
    read -p "请输入通知邮件的地址:" from
    read -p "请输入SMTP服务器地址:" smtp
    read -p "请输入SMTP登陆用户:" smtp_auth_user
    read -p "请输入SMTP登陆密码:" smtp_auth_password
    cat > ~/.mailrc <<EOF
set from=${from}
set smtp=${smtp}
set smtp-auth-user=${smtp_auth_user}
set smtp-auth-password=${smtp_auth_password}
set smtp-auth=login
EOF
fi
# 添加github登陆信息
if [[ ! -f ~/.netrc ]];then
    echo 下面录入github登陆信息
    read -p "请输入github的登陆用户:" user
    read -p "请输入github token:" token
    cat > ~/.netrc <<EOF
machine api.github.com
    login ${user}
    password ${token}

machine uploads.github.com
    login ${user}
    password ${token}
EOF
fi
# 没有项目repo则clone之
if [[ ! -d ~/TranslateProject/.git ]];then
    git clone git@github.com:${user}/TranslateProject.git
fi

if [[ ! -d ~/lctt-scripts ]];then
    git clone https://github.com/LCTT/lctt-scripts
    sed -i '/ProjectRoot=/cProjectRoot=~/TranslateProject' ./lctt-scripts/lctt.cfg
    sed -i "/GithubUser=/cGithubUser=${user}" ~/lctt-scripts/lctt.cfg
fi

if [[ ! -d ~/.ssh ]];then
    echo "生成sshkey"
    ssh-keygen -N "" -f ~/.ssh/id_rsa
    echo "请将下列公钥内容加入github中:"
    cat ~/.ssh/id_rsa.pub
fi


git config --global user.name "${user}"
git config --global user.email "${from}"

exec $*
