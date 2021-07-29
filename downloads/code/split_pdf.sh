#!/bin/bash - 
#===============================================================================
#
#          FILE: split_pdf.sh
# 
#         USAGE: ./split_pdf.sh xxx.pdf
# 
#===============================================================================

#######color code########
RED="31m"
GREEN="32m"
YELLOW="33m"
BLUE="36m"

###############################
colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

colorEchoN(){
    COLOR=$1
    echo -n -e "\033[${COLOR}${@:2}\033[0m"
}

CUR_DIR=$(cd $(dirname $0); pwd)

QPDF=${CUR_DIR}/qpdf-8.4.2/bin/qpdf.exe

splitPdf(){
    PDF_FILE=$1

    if [[ "${PDF_FILE}" == "exit" ]]; then
        colorEcho $RED "exit"
        exit
    fi

    if [[ ! -e ${PDF_FILE} ]]; then
        colorEcho $RED "没有找到该文件"
        continue
    fi

    EXT=${PDF_FILE##*.}
    if [[ "${EXT}" != "pdf" && "${EXT}" != "PDF" ]]; then
        colorEcho $RED "不是pdf文件"
        continue
    fi

    DEST_DIR=${PDF_FILE}.d
    mkdir -p ${DEST_DIR}
    
    TotalPage=$(${QPDF} ${PDF_FILE} --show-npages)
    
    ## 逆序
    Page1=$(seq 1 2 $TotalPage | tac | paste -sd,)
    Page2=$(seq 2 2 $TotalPage | tac | paste -sd,)
    
    ${QPDF} ${PDF_FILE} --pages ${PDF_FILE} $Page1 -- ${DEST_DIR}/1.pdf
    ${QPDF} ${PDF_FILE} --pages ${PDF_FILE} $Page2 -- ${DEST_DIR}/2.pdf

    colorEcho $GREEN "分割完成，请在同名目录下查看。"
}

colorEcho $GREEN "-------------------------------------------------------------"
colorEcho $GREEN "欢迎使用pdf分割工具"
colorEcho $GREEN ""
colorEcho $GREEN "该工具基于qpdf,更高级的应用请查看qpdf --help"
colorEchoN $GREEN "该工具会将pdf文件分割成"
colorEchoN $BLUE  "纯单页pdf(1.pdf)"
colorEchoN $GREEN "和"
colorEchoN $BLUE  "纯双页pdf(2.pdf)"
colorEcho  $GREEN ""
colorEchoN $GREEN "分割后的文建保存在"
colorEchoN $BLUE  "pdf文件.d"
colorEcho  $GREEN "目录下"
colorEcho $YELLOW "运行中的warning可以忽略,不影响结果"
colorEcho $GREEN "-------------------------------------------------------------"
colorEcho $GREEN ""
while true; do
    colorEchoN $GREEN "请输入pdf文件(Ctrl-c/exit-退出,直接拉文件到窗口即可):"
    read PDF_FILE
    splitPdf "$PDF_FILE"
done


