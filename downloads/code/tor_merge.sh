#!/bin/bash

##
## kingwen0302
##
## ��һ�����ϲ����뵽������/��֧
## ��windows����, ��˱�����gbk������utf8
## ��Ҫ��װgit for windows
## sh tor_merge.sh ��֧�汾 1,3-4
## 

CUR_DIR=$(cd $(dirname $0); pwd)
## �ȶ����ĵ�ַ
## svn�˺�����
SVN_BASE_URL="svn://url/xxx"
SVN_PARAM="--username kingwen0302 --password xxxxx"
## �ϲ���Դ��ַ
SRC_SVN_URL="${SVN_BASE_URL}/trunk_cn_s"
## ��ǰĿ¼��� �ȶ�/��֧ Ŀ¼
RELATIVE_DIR="$CUR_DIR/../"

## ## �����ȶ���/��֧��Ŀ¼
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
    echo "��Ѱ >=$MIN_VER �汾�ķ�֧ ..."
    stable_dir=$(svn list $SVN_BASE_URL $SVN_PARAM | grep trunk_.*_s)
    for i in ${stable_dir[@]}; do
        echo "�����ȶ���: $RELATIVE_DIR/$i"
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
                echo "���ַ�֧: $RELATIVE_DIR/$i/$j"
                DEST_DIR_LIST="$DEST_DIR_LIST $RELATIVE_DIR/$i/$j"
            fi
        done
    done
}

## �ϲ�һ����֧
function svn_merge_one(){
    dest_dir=$1
    version=$2
    ## �������ɵ�ַ
    dest_dir="$(dirname $dest_dir)/$(basename $dest_dir)"
    if [ ! -d "${dest_dir}" ]; then
        svn_dir=$(basename $(dirname ${dest_dir}))/$(basename ${dest_dir})
        svn co $SVN_PARAM ${SVN_BASE_URL}/$svn_dir $dest_dir
    fi
    echo "����Ŀ¼: ${dest_dir}" && cd $dest_dir && svn up
    TortoiseProc /command:merge /fromurl:$SRC_SVN_URL /revrange:${version/:/-} /path:"*" /closeonend:1
    TortoiseProc /command:commit /path:"*" /closeonend:1
}

function svn_merge(){
    echo "ԴUrl: ${SRC_SVN_URL}"
    echo "�汾: $1"
    for dest_dir in ${DEST_DIR_LIST[@]}; do
        echo "Ŀ���֧: ${dest_dir}"
        read -p "�Ƿ�ϲ�(Y|N):"
        case $REPLY in
            Y|y)
                svn_merge_one $dest_dir $1
                ;;
            *)
                echo "��ȡ���˱��κϲ�"
                ;;
        esac
    done
}

function help(){
    echo "ʹ��1: $0 BRANCH_VERSION ver,ver1:ver2"
    echo "ʹ��2: $0 BRANCH_VERSION ver,ver1-ver2"
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
