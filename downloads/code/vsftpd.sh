#!/bin/bash

## --------------------------------------
## 配置
## -------------------------------------
## 创建的账户
VUSER=ftp_v_user
## 账户的默认目录
DEFAULT_DIR=/data/ftp_v_user

function help(){
    echo "-----------------------------"
    echo " 1 - install"
    echo " 2 - add user"
    echo "     ex. $0 2 username passwd"
    echo " 3 - uninstall vsftpd"
    echo " 4 - reload"
    echo "-----------------------------"

}

function uninstall(){
    yum -y remove vsftpd
    rm -rf /etc/vsftpd
}
function install(){
    uninstall
    yum -y install vsftpd
    ## 修改配置   
    cat > /etc/vsftpd/vsftpd.conf << EOF
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
anon_upload_enable=YES
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
chroot_local_user=YES
listen=YES
userlist_enable=YES
tcp_wrappers=YES

pasv_enable=YES
pasv_min_port=6000
pasv_max_port=7000

guest_enable=YES
guest_username=${VUSER}
pam_service_name=vsftpd.${VUSER}
user_config_dir=/etc/vsftpd/${VUSER}_dir
EOF
    ## 增加pam认证
    cat > /etc/pam.d/vsftpd.${VUSER} << EOF
auth required pam_userdb.so db=/etc/vsftpd/${VUSER}
account required pam_userdb.so db=/etc/vsftpd/${VUSER}
EOF
    ## 增加虚拟目录
    cd /etc/vsftpd
    touch ${VUSER}
    mkdir ${VUSER}_dir
    ## 增加虚拟账号的user
    useradd -d ${DEFAULT_DIR} -s /sbin/nologin ${VUSER}
    ## 增加端口
    iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 21 -j ACCEPT
    iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 20 -j ACCEPT
    iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 6000:7000 -j ACCEPT
    ## 增加虚拟用户
    add_vuser ftptest ftptest
}

function create_db(){
    db_load -T -t hash -f /etc/vsftpd/${VUSER} /etc/vsftpd/${VUSER}.db
    service vsftpd restart
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
    echo $ftp_user >> /etc/vsftpd/${VUSER}
    echo $ftp_pass >> /etc/vsftpd/${VUSER}
    mkdir -p ${DEFAULT_DIR}/${ftp_user}
    chown ${VUSER}:${VUSER} ${DEFAULT_DIR}/${ftp_user} -R
    cat > /etc/vsftpd/${VUSER}_dir/${ftp_user} << EOF
local_root=${DEFAULT_DIR}/${ftp_user}
write_enable=YES
anon_umask=022
anon_world_readable_only=NO
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
EOF
    create_db
    echo "add finish"
}

case $1 in
[1]) install;;
[2]) add_vuser $2 $3;;
[3]) uninstall;;
[4]) create_db;;
*) help;;
esac
