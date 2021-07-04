#!/bin/bash

PORT=${MYSQL_PORT}
DB_PATH=${MYSQL_PATH}
CNF_PATH=/etc/my.cnf.${PORT}
SOCK_FILE=/tmp/mysql_${PORT}.sock
DB_PASS=${DB_PASSWORD}

echo "初始化数据库"
mysql_install_db --user=mysql --datadir=${DB_PATH}

cat > ${CNF_PATH} << EOF
[mysqld]
port=${PORT}
datadir=${DB_PATH}
socket=${SOCK_FILE}
user=mysql
symbolic-links=0
innodb_file_per_table
max_connections=400
[mysqld_safe]
log-error=/var/log/mysqld_${PORT}.log
pid-file=/var/run/mysqld/mysqld_${PORT}.pid
EOF

echo "启动守护进程"
mysqld_safe --defaults-file=${CNF_PATH} 2>&1 > /dev/null &

while true
do
    if [ -S ${SOCK_FILE} ]; then
        echo "."
        break
    fi
    echo -n "."
    sleep 1
done

echo "初始化密码"
mysqladmin -u root password ${DB_PASS} -S ${SOCK_FILE}

echo "权限设置"
cat > tmp.sql << EOF
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}'; 
flush privileges;
EOF
mysql -uroot -p${DB_PASS} -S ${SOCK_FILE} -e "source tmp.sql;"

echo "完成"
## 关闭数据库
## mysqladmin -u root -p${DB_PASS} -S ${SOCK_FILE} shutdown
