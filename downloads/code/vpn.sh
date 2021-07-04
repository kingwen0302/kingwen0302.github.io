#!/bin/bash

## #############################
## VPN服务器安装脚本
## PASSWD_LEN, SERVER_IP要手动配置
## #############################

## 生成的密码长度
PASSWD_LEN=20
## 服务器IP
SERVER_IP=

function installVPN(){
	echo "begin to install VPN services";
	
    ## 刪除原有的pptpd&ppp
	yum remove -y pptpd ppp
	iptables --flush POSTROUTING --table nat
	iptables --flush FORWARD
	rm -rf /etc/pptpd.conf
	rm -rf /etc/ppp
	
    ## yum安裝除pptpd的包
    yum install -y dkms kernel_ppp_mppe ppp
	yum -y install make libpcap iptables gcc-c++ logrotate tar cpio perl pam tcp_wrappers
	
    ## 安裝pptpd
    if [ "$(rpm -qa pptpd)" == "" ]; then
        wget ftp://rpmfind.net/linux/epel/6/x86_64/pptpd-1.4.0-3.el6.x86_64.rpm
        rpm -ivh pptpd-1.4.0-3.el6.x86_64.rpm
    fi

    ## 自动化配置
	mknod /dev/ppp c 108 0 
	echo 1 > /proc/sys/net/ipv4/ip_forward 
	echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
	echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
	echo "localip 172.16.36.1" >> /etc/pptpd.conf
	echo "remoteip 172.16.36.2-254" >> /etc/pptpd.conf
	echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
	echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd

    ## 增加密码
	pass=`openssl rand ${PASSWD_LEN} -base64`
	if [ "$1" != "" ]
	then pass=$1
	fi
	echo "vpn pptpd ${pass} *" >> /etc/ppp/chap-secrets

    ## 開放端口
    iptables --flush POSTROUTING --table nat
	iptables --flush FORWARD
	iptables -t nat -A POSTROUTING -s 172.16.36.0/24 -j SNAT --to-source ${SERVER_IP}
	iptables -A FORWARD -p tcp --syn -s 172.16.36.0/24 -j TCPMSS --set-mss 1356
    iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 53 -j ACCEPT
    iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 1723 -j ACCEPT
    iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 47 -j ACCEPT
    iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited
    iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited
	service iptables save
    
    ## 自启动
	chkconfig iptables on
	chkconfig pptpd on

    ## 启动
	service iptables restart
	service pptpd start

	echo "VPN service is installed, your VPN username is vpn, VPN password is ${pass}"
}

function repaireVPN(){
	echo "begin to repaire VPN";
    iptables --flush POSTROUTING --table nat
	iptables --flush FORWARD
	iptables -t nat -A POSTROUTING -s 172.16.36.0/24 -j SNAT --to-source ${SERVER_IP}
	iptables -A FORWARD -p tcp --syn -s 172.16.36.0/24 -j TCPMSS --set-mss 1356
    iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 53 -j ACCEPT
    iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 1723 -j ACCEPT
    iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 47 -j ACCEPT
    iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited
    iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited
	service iptables save
	service iptables restart
	service pptpd start
}

function addVPNuser(){
	echo -n "input user name:"
	read username
    userpassword=$(openssl rand ${PASSWD_LEN} -base64)
    echo "name: ${username}  password: ${userpassword}"
    echo -n "confirm(Y/N):"
    read confirm
    case $confirm in
        "Y" | "y" )
	        echo "${username} pptpd ${userpassword} *" >> /etc/ppp/chap-secrets
	        service iptables restart
	        service pptpd start
            echo "add user succeed"
            ;;
        *)
            echo "add user fail"
            ;;
    esac
}

function delVPNuser(){
    echo "all users:"
    cat /etc/ppp/chap-secrets | grep -v '^#' | awk '{print $1}'
    echo -n "please select one:"
    read vpn_user
    cat /etc/ppp/chap-secrets | grep -v "^${vpn_user} " > /ect/ppp/chap-secrets
    service iptables restart
    service pptpd start
    echo "del user succeed"
}

function getVPNInfo(){
    echo "VPN Server IP: ${SERVER_IP}"
    echo "VPN Users:"
    echo "user | -- | password | * "
    cat /etc/ppp/chap-secrets | grep -v '^#'
    echo -n "VPN link num:"
    echo $(netstat -nat | grep ESTABLISHED | grep ':1723' | wc -l)
}

function checkConf(){
    if [[ "${SERVER_IP}" == "" ]]; then
        echo -e "\033[31m[ERROR] please set server_ip \033[0m"
        exit
    fi
}

echo "which do you want to?input the number."
echo "1. install VPN service"
echo "2. repaire VPN service"
echo "3. add VPN user"
echo "4. VPN info"
echo "5. del VPN user"
echo -n "please select:"
read num

case "$num" in
[1] ) 
    checkConf
    installVPN
    ;;
[2] ) 
    repaireVPN
    ;;
[3] ) 
    addVPNuser
    ;;
[4] ) 
    getVPNInfo
    ;;
[5] )
    delVPNuser
    ;;
*) echo "nothing,exit";;
esac
