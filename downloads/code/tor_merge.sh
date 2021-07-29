#!/bin/bash

##
## kingwen0302
##
## 从一个服合并代码到其他服/分支
## 在windows下用, 因此编码是gbk而不是utf8
## 需要安装git for windows
## sh tor_merge.sh 分支版本 1,3-4
## 

CUR_DIR=$(cd $(dirname $0); pwd)
## 稳定服的地址
## svn账号密码
SVN_BASE_URL="svn://url/xxx"
SVN_PARAM="--username kingwen0302 --password xxxxx"
## 合并的源地址
SRC_SVN_URL="${SVN_BASE_URL}/trunk_cn_s"
## 当前目录相对 稳定/分支 目录
RELATIVE_DIR="$CUR_DIR/../"

## ## 其他稳定服/分支的目录
## DEST_DIR_LIST=(
## "$CUR_DIR/../trunk_kr_s"
## "$CUR_DIR/../trunk_tw_s"
## ## "$CUR_DIR/../trunk_cn_s"
## "$CUR_DIR/../trunk_vng_s"
## "$CUR_DIR/../branch_cn/jysy_cn_2102700"
## "$CUR_DIR/../branch_cn/jysy_cn_2102701"
## "$CUR_DIR/../branch_kr/jysy_kr_2102700"
## "$CUR_DIR/../branch_vng/jysy_vn_2102700"
## )

DEST_DIR_LIST=""
function find_branch_list(){
    MIN_VER=$1
    echo "搜寻 >=$MIN_VER 版本的分支 ..."
    stable_dir=$(svn list $SVN_BASE_URL $SVN_PARAM | grep trunk_.*_s)
    for i in ${stable_dir[@]}; do
        echo "发现稳定服: $RELATIVE_DIR/$i"
        DEST_DIR_LIST="$DEST_DIR_LIST $RELATIVE_DIR/$i"
    done

    branch_dir=$(svn list $SVN_BASE_URL $SVN_PARAM | grep branch_.*)
    for i in ${branch_dir[@]}; do
        for j in $(svn list $SVN_BASE_URL/$i $SVN_PARAM); do
            ver=$(echo $j | grep -Eo '[0-9]+')
            if [[ "$ver" == "" ]]; then
                ver=0
            fi
            if [ "$ver" -ge "$MIN_VER" ]; then
                echo "发现分支: $RELATIVE_DIR/$i/$j"
                DEST_DIR_LIST="$DEST_DIR_LIST $RELATIVE_DIR/$i/$j"
            fi
        done
    done
}

## 合并一个分支
function svn_merge_one(){
    dest_dir=$1
    version=$2
    ## 重新生成地址
    dest_dir="$(dirname $dest_dir)/$(basename $dest_dir)"
    if [ ! -d "${dest_dir}" ]; then
        svn_dir=$(basename $(dirname ${dest_dir}))/$(basename ${dest_dir})
        svn co $SVN_PARAM ${SVN_BASE_URL}/$svn_dir $dest_dir
    fi
    echo "进入目录: ${dest_dir}" && cd $dest_dir && svn up
    TortoiseProc /command:merge /fromurl:$SRC_SVN_URL /revrange:${version/:/-} /path:"*" /closeonend:1
    TortoiseProc /command:commit /path:"*" /closeonend:1
}

function svn_merge(){
    echo "源Url: ${SRC_SVN_URL}"
    echo "版本: $1"
    for dest_dir in ${DEST_DIR_LIST[@]}; do
        echo "目标分支: ${dest_dir}"
        read -p "是否合并(Y|N):"
        case $REPLY in
            Y|y)
                svn_merge_one $dest_dir $1
                ;;
            *)
                echo "您取消了本次合并"
                ;;
        esac
    done
}

function help(){
    echo "使用1: $0 BRANCH_VERSION ver,ver1:ver2"
    echo "使用2: $0 BRANCH_VERSION ver,ver1-ver2"
    echo "example: $0 2102700 1000,10002-10005"
}

BRANCH_VERSION=$1
SVN_VERSION=$2
if [[ "$BRANCH_VERSION" == "" || "$SVN_VERSION" == "" ]]; then
    help
else
    find_branch_list $BRANCH_VERSION
    svn_merge ${SVN_VERSION}
fi
