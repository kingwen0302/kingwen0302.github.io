#!/bin/bash

## --------------------------------------
## 配置
## -------------------------------------
## 创建的账户
VUSER=ftp_user
## 账户的默认目录
DEFAULT_DIR=/data/ftp_user

function help(){
    echo "-----------------------------"
    echo " 1 - install"
    echo " 2 - add user"
    echo "     ex. $0 2 username passwd"
    echo "     help: man pure-pw"
    echo " 3 - uninstall"
    echo "-----------------------------"

}

function uninstall(){
    yum -y remove pure-ftpd
    rm -rf /etc/pure-ftpd
}
function install(){
    uninstall
    yum -y install pure-ftpd
    ## 修改配置   
    cat > /etc/pure-ftpd/pure-ftpd.conf << EOF
ChrootEveryone              yes
BrokenClientsCompatibility  yes
MaxClientsNumber            50
Daemonize                   yes
MaxClientsPerIP             8
VerboseLog                  yes
DisplayDotFiles             no
AnonymousOnly               no
NoAnonymous                 yes
SyslogFacility              ftp
DontResolve                 yes
MaxIdleTime                 15
PureDB                      /etc/pure-ftpd/pureftpd.pdb
PAMAuthentication           yes
LimitRecursion              10000 8
AnonymousCanCreateDirs      no
MaxLoad                     4
PassivePortRange            6000 7000
AntiWarez                   yes
Umask                       133:022
MinUID                      100
UseFtpUsers                 no
AllowUserFXP                no
AllowAnonymousFXP           no
ProhibitDotFilesWrite       no
ProhibitDotFilesRead        no
AutoRename                  no
AnonymousCantUpload         yes
AltLog                      clf:/var/log/pureftpd.log
CreateHomeDir               yes
PIDFile                     /var/run/pure-ftpd.pid
MaxDiskUsage                99
CustomerProof               yes
EOF
    ## 增加虚拟账号的user
    useradd -d ${DEFAULT_DIR} -s /sbin/nologin ${VUSER}
    ## 增加端口
    iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 21 -j ACCEPT
    iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 6000:7000 -j ACCEPT
}

function add_vuser(){
    if [ "$1" == "" ]; then
        echo "user can not empty."
        exit
    fi

    if [ "$2" == "" ]; then
        echo "pass can not empty."
        exit 
    fi
    ftp_user=$1
    ftp_pass=$2
    mkdir -p ${DEFAULT_DIR}/${ftp_user}
    chown ${VUSER}:${VUSER} ${DEFAULT_DIR}/${ftp_user} -R
    pure-pw useradd ${ftp_user} -u${VUSER} -d ${DEFAULT_DIR}/${ftp_user}
    pure-pw mkdb
    service pure-ftpd restart
    echo "add finish"
}

case $1 in
[1]) install;;
[2]) add_vuser $2 $3;;
[3]) uninstall;;
*) help;;
esac
