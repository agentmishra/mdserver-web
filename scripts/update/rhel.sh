#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
export LANG=en_US.UTF-8

sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config

VERSION_ID=`grep -o -i 'release *[[:digit:]]\+\.*' /etc/redhat-release | grep -o '[[:digit:]]\+' `

if [ $VERSION_ID == '7' ]; then
    yum install -y curl-devel libmcrypt libmcrypt-devel python3-devel
elif [ $VERSION_ID == '8' ]; then
    dnf install -y curl-devel libmcrypt libmcrypt-devel python36-devel
fi

cd /www/server/mdserver-web/scripts && bash lib.sh
chmod 755 /www/server/mdserver-web/data

echo -e "stop mw"
isStart=`ps -ef|grep 'gunicorn -c setting.py app:app' |grep -v grep|awk '{print $2}'`

port=7200
if [ -f /www/server/mdserver-web/data/port.pl ]; then
    port=$(cat /www/server/mdserver-web/data/port.pl)
fi

n=0
while [[ "$isStart" != "" ]];
do
    echo -e ".\c"
    sleep 0.5
    isStart=$(lsof -n -P -i:$port|grep LISTEN|grep -v grep|awk '{print $2}'|xargs)
    let n+=1
    if [ $n -gt 15 ];then
        break;
    fi
done


echo -e "start mw"
cd /www/server/mdserver-web && bash cli.sh start
isStart=`ps -ef|grep 'gunicorn -c setting.py app:app' |grep -v grep|awk '{print $2}'`
n=0
while [[ ! -f /etc/rc.d/init.d/mw ]];
do
    echo -e ".\c"
    sleep 1
    let n+=1
    if [ $n -gt 20 ];then
        echo -e "start mw fail"
        exit 1
    fi
done
echo -e "start mw success"