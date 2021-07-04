#!/bin/bash - 
#===============================================================================
#
#          FILE: xlsx_to_csv.sh
# 
#         USAGE: ./xlsx_to_csv.sh 
# 
#   DESCRIPTION: linux 命令行下查看xlsx文件
#                通过xlsx2csv
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 2016/09/ 2 18:52
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

## 生成csv文件
function xlsx_to_csv(){
    ## 删除所有旧版数据
    for i in $(ls | grep "^xlsx2csv"); do
        rm $i -f
    done
    file_name="$1"
    xlsx2csv -s 0 -i "${file_name}" | awk '/^--------/{++i}{print > "xlsx2csv"i}'
}

## 显示
function show(){
    file_name=$1
    # cat $file_name | sed '2,10d' | sed '4,6d' | sed 's/,,,//g' | sed 's/,$//g' | column -t -s "," -o "|" | more
    cat $file_name | sed -e '2,10d' | sed -e '4,6d' -e 's/,,,//g' -e 's/,$//g' | column -t -s "," -o "|" | more
}

## 显示subsheet
function list_file(){
    for i in $(ls | grep "^xlsx2csv"); do
        echo -n "$i "
        grep -e "^--------" $i
    done
}

## help
function help(){
    echo "----------------------------"
    echo "gen filenmae"
    echo "list"
    echo "show xlsx2csvN"
    echo "----------------------------"
}

case $1 in
    "gen") xlsx_to_csv "$2";;
    "show") show $2;;
    "list") list_file;;
    *) help;;
esac
