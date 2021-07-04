#!/bin/bash

## -----------------------------------
## 生成如下的TMUX窗口
## pane1是发送命令窗口
## 其他panes(接近等高)是接收命令窗口
## -----------------------------------
##
## +-------------+------+
## |      0      |CMD:  |
## +-------------+      |
## |      3      |  1   |
## +-------------+      |
## |      2      |      |
## +-------------+------+
## 

## 配置
PANE_NUM=4

## -------------------------
## 内部函数
## -------------------------
LOCAL_FILE=$0

## 创建tmux
function create(){
    tmux new-session -d -s update
    tmux split-window -h -t update -p 30
    for((index=0; index<$(($PANE_NUM-1));index++)); do
        percent=$(( 100  / ($PANE_NUM - $index) ))
        tmux split-window -v -t update:0.0 -p $percent
    done
    tmux send-keys -t update:0.1 "bash ${LOCAL_FILE}" C-m
    tmux send-keys -t update:0.1 "bash ${LOCAL_FILE} send all 'clear'" C-m
    tmux send-keys -t update:0.1 "bash ${LOCAL_FILE} confirm" C-m
}

## 发送消息
function send(){
    panes=$1
    cmd="$2"
    case $panes in
        "all")
            send_all "${cmd}";;
        *)
            send_one "$panes" "$cmd";;
    esac
}

function send_one(){
    pane=$1
    cmd="$2"
    tmux send-keys -t update:0.$pane "${cmd}"
}

function send_all(){
    cmd="$1"
    for((index=0; index<=$PANE_NUM; index++));do
        if [[ $index -ne 1 ]]; then
            tmux send-keys -t update:0.$index "${cmd}"
        fi
    done
}

## 确认
function confirm(){
    send all "C-m"
}

## 帮助文件
function help(){
    echo "-------------------------------"
    echo " create        -- 创建一个会话"
    echo " send pane cmd -- 发送一个命令"
    echo "   pane 可以是 all or pane编号"
    echo "   cmd 用引号括起来"
    echo "   ctrl-b q 显示pane编号"
    echo " confirm       -- 命令确认"
    echo "-------------------------------"
}

case $1 in
    "create")
        create;;
    "send")
        send "$2" "$3";;
    "confirm")
        confirm;;
    *)
        help;;
esac
