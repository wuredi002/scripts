#!/bin/bash
#function:CentOS7切换yum源
#author:网络条越-2024-7-3

if [ $USER != root ]; then
    echo -e "\033[31m当前不是root用户，请切换至root用户再次运行脚本\033[0m"
    exit
fi

if [ ! -e /opt/default ]; then
    mkdir /opt/default
fi

SL=`ls /etc/yum.repos.d | wc -l`
if [ $SL -eq 8 ]; then
    cp /etc/yum.repos.d/* /opt/default
fi

install_packages() {
sudo yum install -y curl wget vim nano socat firewalld pciutils epel-release jq bc nmap-ncat bind-utils iproute iproute2 python python3 python3-pip git lrzsz update net-tools automake cmake gzip bzip2 zip unzip kernel kernel-devel kernel-headers git-all screen c++ sendmail mailx 2> /dev/null || sudo apt update && sudo apt install -y curl wget vim nano socat firewalld pciutils jq bc netcat-openbsd dnsutils iproute2 python python3 python3-pip git lrzsz gcc gcc-c++ net-tools automake cmake gzip bzip2 zip unzip kernel kernel-devel kernel-headers git-all screen c++ sendmail mailx
}

configure_firewalld() {
    sudo systemctl unmask firewalld
    sudo systemctl start firewalld
    sudo systemctl enable firewalld
    sudo systemctl status firewalld
    firewall-cmd --list-ports
    iptables -I INPUT -p tcp --dport 22:65535 -j ACCEPT
    iptables -I INPUT -p udp --dport 22:65535 -j ACCEPT
    firewall-cmd --zone=public --add-port=22-65535/tcp --permanent
    firewall-cmd --zone=public --add-port=22-65535/udp --permanent
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    iptables-save
}

#阿里云yum仓库
function aliyum {
    rm -rvf /etc/yum.repos.d/*.repo &>/dev/null
    echo -e "\033[34m开始下载阿里云的yum文件\033[0m"
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
    echo -e "\033[34m开始下载阿里云的yum扩展源、提供额外的软件包\033[0m"
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    wget -O /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo	
    if [ $? -eq 0 ]; then
        echo -e "\033[32myum仓库下载成功\033[0m"
        echo -e "\033[34m正在清理原来的yum文件\033[0m" && yum clean all
        echo -e "\033[34m正在重新搭建yum仓库\033[0m" && yum makecache
        echo -e "\033[32m阿里云yum仓库搭建完成，请查看yum文件数量\033[0m" && yum repolist | tail -5 
	fi	
}

#华为云yum仓库
function huaweiyun {
    rm -rvf /etc/yum.repos.d/*.repo &>/dev/null
    echo -e "\033[34m开始下载华为云的yum文件\033[0m"
    wget -O /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-reg.repo
    if [ $? -eq 0 ]; then
        echo -e "\033[32myum 仓库下载成功\033[0m"
        echo -e "\033[34m正在清理原来的yum文件\033[0m" && yum clean all
        echo -e "\033[34m正在重新搭建yum仓库\033[0m" && yum makecache
        echo -e "\033[32m华为云yum仓库搭建完成，请查看yum文件数量\033[0m" && yum repolist | tail -5
    fi
}

#腾讯yum仓库
function tenxun {
    rm -rvf /etc/yum.repos.d/*.repo &>/dev/null
    echo -e "\033[34m开始下载腾讯的yum文件\033[0m"
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo
    if [ $? -eq 0 ]; then
        echo -e "\033[32myum 仓库下载成功\033[0m"
        echo -e "\033[34m正在清理原来的yum文件\033[0m" && yum clean all
        echo -e "\033[34m正在重新搭建yum仓库\033[0m" && yum makecache
        echo -e "\033[32m腾讯yum仓库搭建完成，请查看yum文件数量\033[0m" && yum repolist | tail -5
    fi
}
#网易yum仓库
function wangyi {
    rm -rvf /etc/yum.repos.d/*.repo &>/dev/null
    echo -e "\033[34m开始下载网易的yum文件\033[0m"
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
    if [ $? -eq 0 ]; then
        echo -e "\033[32myum 仓库下载成功\033[0m"
        echo -e "\033[34m正在清理原来的yum文件\033[0m" && yum clean all
        echo -e "\033[34m正在重新搭建yum仓库\033[0m" && yum makecache
        echo -e "\033[32m网易yum仓库搭建完成，请查看yum文件数量\033[0m" && yum repolist | tail -5
    fi
}

#中科大yum仓库
function zhongkeda {
    rm -rvf /etc/yum.repos.d/*.repo &>/dev/null
    echo -e "\033[34m开始下载中科大的yum文件\033[0m"
wget -O CentOS-Base.repo https://lug.ustc.edu.cn/wiki/_export/code/mirrors/help/centos?codeblock=3
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
    if [ $? -eq 0 ]; then
        echo -e "\033[32myum 仓库下载成功\033[0m"
        echo -e "\033[34m正在清理原来的yum文件\033[0m" && yum clean all
        echo -e "\033[34m正在重新搭建yum仓库\033[0m" && yum makecache
        echo -e "\033[32m中科大yum仓库搭建完成，请查看yum文件数量\033[0m" && yum repolist | tail -5
    fi
}

#系统默认源
function default {
    rm -rvf /etc/yum.repos.d/*.repo &>/dev/null
    echo -e "\033[34m开始恢复系统默认源\033[0m"
    cp /opt/default/*  /etc/yum.repos.d/
    echo -e "\033[32myum仓库恢复成功\033[0m"
    echo -e "\033[34m正在清理原来的yum文件\033[0m" && yum clean all
    echo -e "\033[34m正在重新搭建yum仓库\033[0m" && yum makecache
    echo -e "\033[32m默认yum仓库执行完成，请查看yum文件数量\033[0m" && yum repolist | tail -5
}

#case语句；判断键盘输入
echo -e "\033[35m该脚本可部署以下yum仓库：\033[0m"
echo -e "\t\033[36m1、阿里-yum源（推荐）\033[0m"
echo -e "\t\033[36m2、华为-yum源\033[0m"
echo -e "\t\033[36m3、腾讯-yum源\033[0m"
echo -e "\t\033[36m4、网易-yum源\033[0m"
echo -e "\t\033[36m5、中科大-yum源\033[0m"
echo -e "\t\033[36m6、系统默认-yum源\033[0m"
read -p "请输入您想切换的yum源名称：" XZ
case $XZ in
1|阿里-yum源)
    aliyum
    ;;
2|华为-yum源)
    huaweiyun
    ;;
3|腾讯-yum源)
    tenxun
    ;;
4|网易-yum源)	
	wangyi
	;;
5|中科大-yum源)	
	zhongkeda
	;;	
6|系统默认-yum源)
    default
    ;;
*)
    echo -e "\033[31m请您输入正确的yum源(aliyum|huaweiyun|tenxun|wangyi|zhongkeda|default)\033[0m"
    ;;
esac

echo -e "\033[34m 3秒后自动更新最新插件以及开放端口\033[0m"
sleep 3    
    install_packages
    configure_firewalld
