#!/bin/bash - 
#===============================================================================
#
#          FILE: svn_merge.sh
# 
#         USAGE: ./svn_merge.sh 
# 
#   DESCRIPTION: 
#               合并脚本
#               1. 根据版本依次合并
#               2. 遇到冲突使用Ctrl-C中断
#               3. 解决冲突后再次执行,继续合并
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: kingwen0302, kingwen0302@msn.com
#  ORGANIZATION: 
#       CREATED: 2017/5/12 16:15
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

## 配置
SRC_SVN_URL=http://svn_url/server/trunk
SVN_USER="svn_user"
SVN_PASS="svn_pass"

SRC_SVN_URL_BASE=$(basename $SRC_SVN_URL)

CUR_DIR=$(cd $(dirname $0); pwd)
## 已经合并成功的版本号
MERGE_SUCCESS_VERSION=${CUR_DIR}/versions
## 已经合并成功的注释
MERGE_SUCCESS_COMMENT=${CUR_DIR}/comment

export SVN_EDITOR="vim"

function svn_merge_one(){
    version=$1
    ## 如果svn是中文的话,要过滤中文
    merge_files=$(svn log -r ${version} -qv ${SRC_SVN_URL} --username ${SVN_USER} --password ${SVN_PASS} | grep -v "^r" | grep -v "^Changed paths:" | grep -v "^-------------" | awk "{print \$1\$2}")

    base_merge_files=""
    for f in $merge_files; do
        if [[ $base_merge_files == "" ]]; then
            base_merge_files=$(basename $f)
        else
            base_merge_files="${base_merge_files} $(basename $f)"
        fi
    done

    if [ "$base_merge_files" != "" ]; then
        echo "==>START MERGE ${version} [${base_merge_files}]"
        for f in ${merge_files}; do
            svn_cmd=$(expr substr $f 1 1)
            f=$(echo $f | sed -e "s/^.//" | sed -e "s/${SRC_SVN_URL_BASE}//"  | sed -e "s/\/\//\//g" | sed -e "s/\/\//\//g")
            local_f=".$f"
            case $svn_cmd in
                A)
                    tmp="svn copy --username ${SVN_USER} --password ${SVN_PASS} -r $version ${SRC_SVN_URL}$f $local_f"
                    ;;
                M)
                    ## tmp="svn merge --username ${SVN_USER} --password ${SVN_PASS} -r $((version-1)):$version --ignore-ancestry ${SRC_SVN_URL}$f $local_f"
                    tmp="svn merge --username ${SVN_USER} --password ${SVN_PASS} -c $version --ignore-ancestry ${SRC_SVN_URL}$f $local_f"
                    ;;
                D)
                    tmp="svn del $local_f"
                    ;;
                *)
                    echo "暂不支持的命令"
                    exit
                    ;;
            esac
            ttmp=$($tmp)
            if [ $? -ne 0 ]; then
                echo "    [FAIL]$ttmp"
                exit
            else
                echo "    [SUCCESS]$f"
            fi
        done

        ## 写入合并成功版本号
        echo "$version" >> ${MERGE_SUCCESS_VERSION}
        ## 写入合并成功日志
        svn log -r ${version} -v ${SRC_SVN_URL} --username ${SVN_USER} --password ${SVN_PASS} | grep -v "^r" | grep -v "^Changed paths:" | grep -v "^-------------" | grep -v "^$" | grep -v "^ " >> ${MERGE_SUCCESS_COMMENT}
    fi
}

if [ $# -eq 0 ]; then
    echo "---------------------"
    echo "$0 version1:version2 version3 "
    echo "---------------------"
    exit
fi

while true; do
    if [ $# -eq 0 ]; then
        break
    else

        ## 确保文件存在
        touch ${MERGE_SUCCESS_VERSION}
        touch ${MERGE_SUCCESS_COMMENT}
        ## 获取版本
        f_version=$(echo $1 | cut -d : -f 1)
        t_version=$(echo $1 | cut -d : -f 2)
        for version in $(seq $f_version $t_version); do
            ## 是否已经合并成功
            is_merge_success=0
            for v in $(cat ${MERGE_SUCCESS_VERSION}); do
                if [ "${v}" == "$version" ]; then
                    is_merge_success=1
                fi
            done
            if [ $is_merge_success -eq 0 ]; then
                svn_merge_one $version
            fi
        done
    fi
    shift
done

mv ${MERGE_SUCCESS_VERSION} ${MERGE_SUCCESS_VERSION}_bak
cat ${MERGE_SUCCESS_COMMENT}
mv ${MERGE_SUCCESS_COMMENT} ${MERGE_SUCCESS_COMMENT}_bak
