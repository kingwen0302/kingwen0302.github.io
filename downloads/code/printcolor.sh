#!/bin/bash
RED_FG="31m"; GREEN_FG="32m"; YELLOW_FG="33m"; BLUE_FG="36m"
RED_BG="41m"; GREEN_BG="42m"; YELLOW_BG="43m"; BLUE_BG="46m"

function _print_info(){
    echo -n -e "\033[${GREEN_FG}${@:1}\033[0m"
}

function _print_warn() {
    echo -n -e "\033[${YELLOW_FG}${@:1}\033[0m"
}

function _print_error(){
    echo -n -e "\033[${RED_FG}[ERROR]\033[0m ${@:1}"
}

function _print_ask(){
    echo -n -e "\033[${YELLOW_FG}${@:1}\033[0m"
}

function print_info(){
    echo -e "\033[${GREEN_FG}${@:1}\033[0m"
}

function print_warn() {
    echo -e "\033[${YELLOW_FG}${@:1}\033[0m"
}

function print_error(){
    echo -e "\033[${RED_FG}[ERROR]\033[0m ${@:1}"
}

function print_ask(){
    echo -e "\033[${YELLOW_FG}${@:1}\033[0m"
}

function is_exist_dir() {
    dir=$1
    [ -d $dir ]
}

function is_exist_file() {
    file=$1
    [ -f $file ]
}


