#!/bin/bash

## 博客根目录
HEXO_ROOT_DIR=/data/blog
## 博客源文件目录
MY_BLOG_GIT_URL="git@git.coding.net:kingwen0302/kingwen0302.git"
## 博客主题
MY_BLOG_THEME="https://github.com/tufu9441/maupassant-hexo.git"
MY_BLOG_THEME_NAME=maupassant
## 当前目录
CUR_DIR=$(cd $(dirname $0); pwd)

function install_hexo(){
    yum remove nodejs npm -y
    curl --silent --location https://rpm.nodesource.com/setup_4.x | bash -
    yum install -y nodejs
    ## npm install -g cnpm --registry=https://registry.npm.taobao.org
    ## cnpm install hexo-cli -g
}
function install(){
    hexo init ${HEXO_ROOT_DIR}
    cd ${HEXO_ROOT_DIR}
    rm -rf source
    git clone ${MY_BLOG_GIT_URL} source
    rm -rf themes/landscape
    git clone ${MY_BLOG_THEME} themes/${MY_BLOG_THEME_NAME}
    ## HEXO配置替换
    source ${CUR_DIR}/maupassant_config.sh
    source ${CUR_DIR}/post.sh
    ## THEME配置替换
    source ${CUR_DIR}/maupassant_theme_config.sh
    npm install
    ## 安装deploy
    npm install hexo-deployer-git --save
    ## rss支持
    npm install hexo-generator-feed --save
    ## sitemap支持
    npm install hexo-generator-sitemap --save
    npm install hexo-generator-baidu-sitemap --save
    ## jade模版
    npm install hexo-renderer-jade --save
    npm install hexo-renderer-sass --save
}

function deploy(){
    cd ${HEXO_ROOT_DIR}/source
    git add .
    git commit -m "$(date) deploy"
    cd ${HEXO_ROOT_DIR}
    hexo g -d
}

function help(){
    echo "------------------------------"
    echo " 0 -- install_hexo"
    echo " 1 -- install"
    echo " 2 -- deploy"
    echo "------------------------------"

}
case $1 in
    [0]) install_hexo;;
    [1]) install;;
    [2]) deploy;;
    *)   help;;
esac
