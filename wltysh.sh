#!/bin/bash
# 网络跳越(hijk) 
# 到期时间设置（修改这里设置到期时间）
EXPIRATION_DATE="2026-11-03"
CURRENT_DATE=$(date +%Y-%m-%d)

# 检查是否到期
check_expiration() {
    if [[ "$CURRENT_DATE" > "$EXPIRATION_DATE" ]]; then
        echo -e "${RED}脚本已过期，请联系作者获取新版本！${NC}"
        exit 1
    fi
}

show_expiration_info() {
    days_remaining=$(( ($(date -d "$EXPIRATION_DATE" +%s) - $(date +%s)) / 86400 ))
    if [ $days_remaining -le 7 ]; then
        echo -e "${RED}警告: 脚本将在 $days_remaining 天后过期!${NC}"
    else
        echo -e "${GREEN}脚本有效期至: $EXPIRATION_DATE (剩余 $days_remaining 天)${NC}"
    fi
}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

timeout() {
    timeout=0
    timeout_str=""
    while [[ ${timeout} -le 30 ]]; do
        let timeout++
        timeout_str+="#"
    done
    let timeout=timeout+5
    while [[ ${timeout} -gt 0 ]]; do
        let timeout--
        if [[ ${timeout} -gt 25 ]]; then
            let timeout_color=32
            let timeout_bg=42
            timeout_index="3"
        elif [[ ${timeout} -gt 15 ]]; then
            let timeout_color=33
            let timeout_bg=43
            timeout_index="2"
        elif [[ ${timeout} -gt 5 ]]; then
            let timeout_color=31
            let timeout_bg=41
            timeout_index="1"
        else
            timeout_index="0"
        fi
        printf "${Warning} ${GreenBG} %d%s%s ${Font} \033[%d;%dm%-s\033[0m \033[%dm%d\033[0m \r" \
            "$timeout_index" \
            " $(gettext "秒后") " \
            "$1" \
            "$timeout_color" \
            "$timeout_bg" \
            "$timeout_str" \
            "$timeout_color" \
            "$timeout_index"
        sleep 0.1
        timeout_str=${timeout_str%?}
        [[ ${timeout} -eq 0 ]] && printf "\n"
    done
}

# 状态文件路径 - 使用持久化位置
STATUS_FILE="/root/.wlty_executed"
execute_once() {
    if [ ! -f "$STATUS_FILE" ]; then
        echo "首次运行，执行一次性初始化..."
        execut
        # 创建状态文件标记已执行
        touch "$STATUS_FILE"
        echo "初始化完成: $STATUS_FILE"
    #else
        #echo "状态文件存在: $STATUS_FILE"
    fi
}

execut() {
echo "=== 开始系统依赖安装 ==="
if [ -x "$(command -v yum)" ]; then
    echo "检测到 CentOS/RHEL 系统，使用 yum 安装..."
    yum update -y
    yum install -y curl wget jq vim nano socat firewalld pciutils epel-release bc nmap-ncat bind-utils iproute python3 git lrzsz net-tools automake cmake gzip bzip2 zip unzip kernel kernel-devel kernel-headers git-all screen sendmail
    echo "配置 CentOS/RHEL 防火墙..."
    systemctl enable --now firewalld
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --reload 
elif [ -x "$(command -v apt-get)" ]; then
    echo "检测到 Debian/Ubuntu 系统，使用 apt 安装..."
    apt update -y
    apt full-upgrade -y
    apt install -y curl wget jq vim nano socat firewalld pciutils bc ncat nmap-ncat bind-utils iproute python3 git lrzsz net-tools automake cmake gzip bzip2 zip unzip kernel kernel-devel kernel-headers git-all screen sendmail linux-headers-$(uname -r) git screen sendmail
echo ""
else
    echo "错误：不支持的包管理器"
    exit 1
fi
echo "=== 系统依赖安装配置完成！ ==="
echo ""
echo ""
    clear
}

bbr() {
#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================
#	System Required: CentOS 6/7,Debian 8/9,Ubuntu 16+
#	Description: BBR+BBR魔改版+BBRplus新版+Lotserver
#	Version: 2.0.0
#	Author: hijk
#   推荐使用5.5以上内核直接开启的bbr速度最佳
#=================================================

sh_ver="2.0.0"
github="raw.githubusercontent.com/chiakge/Linux-NetSpeed/master"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

#安装BBR内核
installbbr(){
	kernel_version="4.11.8"
	if [[ "${release}" == "centos" ]]; then
		rpm --import http://${github}/bbr/${release}/RPM-GPG-KEY-elrepo.org
		yum install -y http://${github}/bbr/${release}/${version}/${bit}/kernel-ml-${kernel_version}.rpm
		yum remove -y kernel-headers
		yum install -y http://${github}/bbr/${release}/${version}/${bit}/kernel-ml-headers-${kernel_version}.rpm
		yum install -y http://${github}/bbr/${release}/${version}/${bit}/kernel-ml-devel-${kernel_version}.rpm
	elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		mkdir bbr && cd bbr
		wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.1d-0+deb10u2_amd64.deb
		wget -N --no-check-certificate http://${github}/bbr/debian-ubuntu/linux-headers-${kernel_version}-all.deb
		wget -N --no-check-certificate http://${github}/bbr/debian-ubuntu/${bit}/linux-headers-${kernel_version}.deb
		wget -N --no-check-certificate http://${github}/bbr/debian-ubuntu/${bit}/linux-image-${kernel_version}.deb
	
		dpkg -i libssl1.1_1.1.1d-0+deb10u2_amd64.deb
		dpkg -i linux-headers-${kernel_version}-all.deb
		dpkg -i linux-headers-${kernel_version}.deb
		dpkg -i linux-image-${kernel_version}.deb
		cd .. && rm -rf bbr
	fi
	detele_kernel
	BBR_grub
	echo -e "${Tip} 重启VPS后，请重新运行脚本开启${Red_font_prefix}BBR/BBR魔改版${Font_color_suffix}"
	stty erase '^H' && read -p "需要重启VPS后，才能开启BBR/BBR魔改版，是否现在重启 ? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS 重启中..."
		reboot
	fi
}

#安装BBRplus新版内核 (6.x稳定版)
installbbrplus(){
	github_ver_plus=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases | grep /bbrplus-6.x_stable/releases/tag/ | head -1 | awk -F "[/]" '{print $8}' | awk -F "[\"]" '{print $1}')
	github_ver_plus_num=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases | grep /bbrplus-6.x_stable/releases/tag/ | head -1 | awk -F "[/]" '{print $8}' | awk -F "[\"]" '{print $1}' | awk -F "[-]" '{print $1}')
	
	if [[ -z "$github_ver_plus" ]]; then
		echo -e "${Error} 无法获取BBRplus新版内核版本号，请检查网络连接！"
		exit 1
	fi

	echo -e "${Info} 获取的BBRplus新版版本号为: ${Green_font_prefix}${github_ver_plus}${Font_color_suffix}"
	echo -e "${Tip} 如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈"
	
	rm -rf bbrplusnew
	mkdir bbrplusnew && cd bbrplusnew || exit
	
	if [[ "${release}" == "centos" ]]; then
		if [[ ${version} == "7" ]]; then
			if [[ ${bit} == "x86_64" ]]; then
				kernel_version=${github_ver_plus_num}-bbrplus
				detele_kernel_head
				
				# 获取下载链接
				headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases' | grep "${github_ver_plus}" | grep 'rpm' | grep 'headers' | grep 'el7' | awk -F '"' '{print $4}' | head -1)
				imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases' | grep "${github_ver_plus}" | grep 'rpm' | grep -v 'devel' | grep -v 'headers' | grep -v 'Source' | grep 'el7' | awk -F '"' '{print $4}' | head -1)
				
				if [[ -z "$headurl" || -z "$imgurl" ]]; then
					echo -e "${Error} 无法获取内核下载链接！"
					cd .. && rm -rf bbrplusnew
					exit 1
				fi
				
				echo -e "${Info} 正在下载内核..."
				wget -O kernel-headers-c7.rpm "$headurl"
				wget -O kernel-c7.rpm "$imgurl"
				
				echo -e "${Info} 正在安装内核..."
				yum install -y kernel-c7.rpm
				yum install -y kernel-headers-c7.rpm
			else
				echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
			fi
		elif [[ ${version} == "8" ]]; then
			echo -e "${Info} CentOS 8 支持BBRplus新版内核..."
			if [[ ${bit} == "x86_64" ]]; then
				kernel_version=${github_ver_plus_num}-bbrplus
				detele_kernel_head
				
				headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases' | grep "${github_ver_plus}" | grep 'rpm' | grep 'headers' | grep 'el8' | awk -F '"' '{print $4}' | head -1)
				imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases' | grep "${github_ver_plus}" | grep 'rpm' | grep -v 'devel' | grep -v 'headers' | grep -v 'Source' | grep 'el8' | awk -F '"' '{print $4}' | head -1)
				
				if [[ -z "$headurl" || -z "$imgurl" ]]; then
					echo -e "${Error} 无法获取内核下载链接！"
					cd .. && rm -rf bbrplusnew
					exit 1
				fi
				
				wget -O kernel-c8.rpm "$headurl"
				wget -O kernel-headers-c8.rpm "$imgurl"
				yum install -y kernel-c8.rpm
				yum install -y kernel-headers-c8.rpm
			else
				echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
			fi
		else
			echo -e "${Error} BBRplus新版内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		if [[ ${bit} == "x86_64" ]]; then
			kernel_version=${github_ver_plus_num}-bbrplus
			detele_kernel_head
			
			headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases' | grep "${github_ver_plus}" | grep 'https' | grep 'amd64.deb' | grep 'headers' | awk -F '"' '{print $4}' | head -1)
			imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases' | grep "${github_ver_plus}" | grep 'https' | grep 'amd64.deb' | grep 'image' | awk -F '"' '{print $4}' | head -1)
			
			if [[ -z "$headurl" || -z "$imgurl" ]]; then
				echo -e "${Error} 无法获取内核下载链接！"
				cd .. && rm -rf bbrplusnew
				exit 1
			fi
			
			wget -O linux-headers-d10.deb "$headurl"
			wget -O linux-image-d10.deb "$imgurl"
			dpkg -i linux-image-d10.deb
			dpkg -i linux-headers-d10.deb
		elif [[ ${bit} == "aarch64" ]]; then
			echo -e "${Info} 检测到ARM64架构，安装ARM64版BBRplus新版内核..."
			kernel_version=${github_ver_plus_num}-bbrplus
			detele_kernel_head
			
			headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases' | grep "${github_ver_plus}" | grep 'https' | grep 'arm64.deb' | grep 'headers' | awk -F '"' '{print $4}' | head -1)
			imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases' | grep "${github_ver_plus}" | grep 'https' | grep 'arm64.deb' | grep 'image' | awk -F '"' '{print $4}' | head -1)
			
			if [[ -z "$headurl" || -z "$imgurl" ]]; then
				echo -e "${Error} 无法获取内核下载链接！"
				cd .. && rm -rf bbrplusnew
				exit 1
			fi
			
			wget -O linux-headers-d10.deb "$headurl"
			wget -O linux-image-d10.deb "$imgurl"
			dpkg -i linux-image-d10.deb
			dpkg -i linux-headers-d10.deb
		else
			echo -e "${Error} 不支持x86_64及arm64/aarch64以外的系统 !" && exit 1
		fi
	fi

	cd .. && rm -rf bbrplusnew
	BBR_grub
	echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
	echo -e "${Info} BBRplus新版内核版本: ${Green_font_prefix}${kernel_version}${Font_color_suffix}"
	stty erase '^H' && read -p "需要重启VPS后，才能开启BBRplus新版，是否现在重启 ? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS 重启中..."
		reboot
	fi
}

#安装Lotserver内核
installlot(){
	if [[ "${release}" == "centos" ]]; then
		rpm --import http://${github}/lotserver/${release}/RPM-GPG-KEY-elrepo.org
		yum remove -y kernel-firmware
		yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-firmware-${kernel_version}.rpm
		yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-${kernel_version}.rpm
		yum remove -y kernel-headers
		yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-headers-${kernel_version}.rpm
		yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-devel-${kernel_version}.rpm
	elif [[ "${release}" == "ubuntu" ]]; then
		bash <(wget --no-check-certificate -qO- "http://${github}/Debian_Kernel.sh")
	elif [[ "${release}" == "debian" ]]; then
		bash <(wget --no-check-certificate -qO- "http://${github}/Debian_Kernel.sh")
	fi
	detele_kernel
	BBR_grub
	echo -e "${Tip} 重启VPS后，请重新运行脚本开启${Red_font_prefix}Lotserver${Font_color_suffix}"
	stty erase '^H' && read -p "需要重启VPS后，才能开启Lotserver，是否现在重启 ? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS 重启中..."
		reboot
	fi
}

#启用BBR
startbbr(){
	remove_all
	if [[ `echo ${kernel_version} | awk -F'.' '{print $1}'` -ge "5" ]]; then
		echo "net.core.default_qdisc=cake" >> /etc/sysctl.conf
		echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	else
		echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
		echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	fi
	sysctl -p
	echo -e "${Info}BBR启动成功！"
}

#启用BBRplus
startbbrplus(){
	remove_all
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbrplus" >> /etc/sysctl.conf
	sysctl -p
	echo -e "${Info}BBRplus启动成功！"
}

#编译并启用BBR魔改
startbbrmod(){
	remove_all
	if [[ "${release}" == "centos" ]]; then
		yum install -y make gcc
		mkdir bbrmod && cd bbrmod
		wget -N --no-check-certificate http://${github}/bbr/tcp_tsunami.c
		echo "obj-m:=tcp_tsunami.o" > Makefile
		make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc
		chmod +x ./tcp_tsunami.ko
		cp -rf ./tcp_tsunami.ko /lib/modules/$(uname -r)/kernel/net/ipv4
		insmod tcp_tsunami.ko
		depmod -a
	else
		apt-get update
		if [[ "${release}" == "ubuntu" && "${version}" = "14" ]]; then
			apt-get -y install build-essential
			apt-get -y install software-properties-common
			add-apt-repository ppa:ubuntu-toolchain-r/test -y
			apt-get update
		fi
		apt-get -y install make gcc
		mkdir bbrmod && cd bbrmod
		wget -N --no-check-certificate http://${github}/bbr/tcp_tsunami.c
		echo "obj-m:=tcp_tsunami.o" > Makefile
		ln -s /usr/bin/gcc /usr/bin/gcc-4.9
		make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc-4.9
		install tcp_tsunami.ko /lib/modules/$(uname -r)/kernel
		cp -rf ./tcp_tsunami.ko /lib/modules/$(uname -r)/kernel/net/ipv4
		depmod -a
	fi
	

	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=tsunami" >> /etc/sysctl.conf
	sysctl -p
    cd .. && rm -rf bbrmod
	echo -e "${Info}魔改版BBR启动成功！"
}

#编译并启用BBR魔改
startbbrmod_nanqinlang(){
	remove_all
	if [[ "${release}" == "centos" ]]; then
		yum install -y make gcc
		mkdir bbrmod && cd bbrmod
		wget -N --no-check-certificate https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbr/centos/tcp_nanqinlang.c
		echo "obj-m := tcp_nanqinlang.o" > Makefile
		make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc
		chmod +x ./tcp_nanqinlang.ko
		cp -rf ./tcp_nanqinlang.ko /lib/modules/$(uname -r)/kernel/net/ipv4
		insmod tcp_nanqinlang.ko
		depmod -a
	else
		apt-get update
		if [[ "${release}" == "ubuntu" && "${version}" = "14" ]]; then
			apt-get -y install build-essential
			apt-get -y install software-properties-common
			add-apt-repository ppa:ubuntu-toolchain-r/test -y
			apt-get update
		fi
		apt-get -y install make gcc-4.9
		mkdir bbrmod && cd bbrmod
		wget -N --no-check-certificate https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbr/tcp_nanqinlang.c
		echo "obj-m := tcp_nanqinlang.o" > Makefile
		make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc-4.9
		install tcp_nanqinlang.ko /lib/modules/$(uname -r)/kernel
		cp -rf ./tcp_nanqinlang.ko /lib/modules/$(uname -r)/kernel/net/ipv4
		depmod -a
	fi
	

	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=nanqinlang" >> /etc/sysctl.conf
	sysctl -p
	echo -e "${Info}魔改版BBR启动成功！"
}

#启用Lotserver
startlotserver(){
	remove_all
	if [[ "${release}" == "centos" ]]; then
		yum install ethtool
	else
		apt-get update
		apt-get install ethtool
	fi
	bash <(wget --no-check-certificate -qO- https://raw.githubusercontent.com/chiakge/lotServer/master/Install.sh) install
	sed -i '/advinacc/d' /appex/etc/config
	sed -i '/maxmode/d' /appex/etc/config
	echo -e "advinacc=\"1\"
maxmode=\"1\"">>/appex/etc/config
	/appex/bin/lotServer.sh restart
	start_menu
}

#卸载全部加速
remove_all(){
	rm -rf bbrmod
	sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
  sed -i '/fs.file-max/d' /etc/sysctl.conf
	sed -i '/net.core.rmem_default/d' /etc/sysctl.conf
	sed -i '/net.core.wmem_default/d' /etc/sysctl.conf
	sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_tw_recycle/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_keepalive_time/d' /etc/sysctl.conf
	sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.conf
	sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
	sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
	sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_max_orphans/d' /etc/sysctl.conf
	sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
	sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
	sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.conf
	sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
	if [[ -e /appex/bin/lotServer.sh ]]; then
		bash <(wget --no-check-certificate -qO- https://github.com/MoeClub/lotServer/raw/master/Install.sh) uninstall
	fi
	clear
	echo -e "${Info}:清除加速完成。"
	sleep 1s
}

#优化系统配置
optimizing_system(){
	sed -i '/fs.file-max/d' /etc/sysctl.conf
	sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
	sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
	sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
	sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
	sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
	sed -i '/net.core.wmem_default/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
	sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
 	sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.conf
	sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
	echo "fs.file-max = 1000000
fs.inotify.max_user_instances = 8192
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_rmem = 16384 262144 8388608
net.ipv4.tcp_wmem = 32768 524288 16777216
net.core.somaxconn = 8192
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.wmem_default = 2097152
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_max_syn_backlog = 10240
net.core.netdev_max_backlog = 10240
net.ipv4.tcp_slow_start_after_idle = 0
# forward ipv4
net.ipv4.ip_forward = 1">>/etc/sysctl.conf
	sysctl -p
	echo "*               soft    nofile           1000000
*               hard    nofile          1000000">/etc/security/limits.conf
	echo "ulimit -SHn 1000000">>/etc/profile
	read -p "需要重启VPS后，才能生效系统优化配置，是否现在重启 ? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS 重启中..."
		reboot
	fi
}

#开始菜单
start_menu(){
clear
echo && echo -e " TCP加速 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- hijk | 网络跳越 --
  
————————————内核管理————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安装 BBR/BBR魔改版内核
 ${Green_font_prefix}2.${Font_color_suffix} 安装 BBRplus新版内核 (6.x稳定版)
 ${Green_font_prefix}3.${Font_color_suffix} 安装 Lotserver(锐速)内核
————————————加速管理————————————
 ${Green_font_prefix}4.${Font_color_suffix} 使用BBR加速
 ${Green_font_prefix}5.${Font_color_suffix} 使用BBR魔改版加速
 ${Green_font_prefix}6.${Font_color_suffix} 使用暴力BBR魔改版加速(不支持部分系统)
 ${Green_font_prefix}7.${Font_color_suffix} 使用BBRplus版加速
 ${Green_font_prefix}8.${Font_color_suffix} 使用Lotserver(锐速)加速
————————————杂项管理————————————
 ${Green_font_prefix}9.${Font_color_suffix} 卸载全部加速
 ${Green_font_prefix}10.${Font_color_suffix} 系统配置优化
 ${Green_font_prefix}0.${Font_color_suffix} 退出脚本
————————————————————————————————" && echo

	check_status
	if [[ ${kernel_status} == "noinstall" ]]; then
		echo -e " 当前状态: ${Green_font_prefix}未安装${Font_color_suffix} 加速内核 ${Red_font_prefix}请先安装内核${Font_color_suffix}"
	else
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} ${_font_prefix}${kernel_status}${Font_color_suffix} 加速内核 , ${Green_font_prefix}${run_status}${Font_color_suffix}"
		
	fi
echo
read -p " 请输入数字 [0-11]:" num
case "$num" in
	1)
	check_sys_bbr
	;;
	2)
	check_sys_bbrplus
	;;
	3)
	check_sys_Lotsever
	;;
	4)
	startbbr
	;;
	5)
	startbbrmod
	;;
	6)
	startbbrmod_nanqinlang
	;;
	7)
	startbbrplus
	;;
	8)
	startlotserver
	;;
	9)
	remove_all
	;;
	10)
	optimizing_system
	;;
	0)
	exit 1
	;;
	*)
	clear
	echo -e "${Error}:请输入正确数字 [0-11]"
	sleep 5s
	start_menu
	;;
esac
}
#############内核管理组件#############

#删除多余内核
detele_kernel(){
	if [[ "${release}" == "centos" ]]; then
		rpm_total=`rpm -qa | grep kernel | grep -v "${kernel_version}" | grep -v "noarch" | wc -l`
		if [ "${rpm_total}" > "1" ]; then
			echo -e "检测到 ${rpm_total} 个其余内核，开始卸载..."
			for((integer = 1; integer <= ${rpm_total}; integer++)); do
				rpm_del=`rpm -qa | grep kernel | grep -v "${kernel_version}" | grep -v "noarch" | head -${integer}`
				echo -e "开始卸载 ${rpm_del} 内核..."
				rpm --nodeps -e ${rpm_del}
				echo -e "卸载 ${rpm_del} 内核卸载完成，继续..."
			done
			echo --nodeps -e "内核卸载完毕，继续..."
		else
			echo -e " 检测到 内核 数量不正确，请检查 !" && exit 1
		fi
	elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		deb_total=`dpkg -l | grep linux-image | awk '{print $2}' | grep -v "${kernel_version}" | wc -l`
		if [ "${deb_total}" > "1" ]; then
			echo -e "检测到 ${deb_total} 个其余内核，开始卸载..."
			for((integer = 1; integer <= ${deb_total}; integer++)); do
				deb_del=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${kernel_version}" | head -${integer}`
				echo -e "开始卸载 ${deb_del} 内核..."
				apt-get purge -y ${deb_del}
				echo -e "卸载 ${deb_del} 内核卸载完成，继续..."
			done
			echo -e "内核卸载完毕，继续..."
		else
			echo -e " 检测到 内核 数量不正确，请检查 !" && exit 1
		fi
	fi
}

#删除多余内核头
detele_kernel_head(){
	if [[ "${release}" == "centos" ]]; then
		rpm_total=`rpm -qa | grep kernel-headers | grep -v "${kernel_version}" | grep -v "noarch" | wc -l`
		if [ "${rpm_total}" > "1" ]; then
			echo -e "检测到 ${rpm_total} 个其余内核头，开始卸载..."
			for((integer = 1; integer <= ${rpm_total}; integer++)); do
				rpm_del=`rpm -qa | grep kernel-headers | grep -v "${kernel_version}" | grep -v "noarch" | head -${integer}`
				echo -e "开始卸载 ${rpm_del} 内核头..."
				rpm --nodeps -e ${rpm_del}
				echo -e "卸载 ${rpm_del} 内核头卸载完成，继续..."
			done
			echo --nodeps -e "内核头卸载完毕，继续..."
		else
			echo -e " 检测到 内核头 数量不正确，请检查 !" && exit 1
		fi
	elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		deb_total=`dpkg -l | grep linux-headers | awk '{print $2}' | grep -v "${kernel_version}" | wc -l`
		if [ "${deb_total}" > "1" ]; then
			echo -e "检测到 ${deb_total} 个其余内核头，开始卸载..."
			for((integer = 1; integer <= ${deb_total}; integer++)); do
				deb_del=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${kernel_version}" | head -${integer}`
				echo -e "开始卸载 ${deb_del} 内核头..."
				apt-get purge -y ${deb_del}
				echo -e "卸载 ${deb_del} 内核头卸载完成，继续..."
			done
			echo -e "内核头卸载完毕，继续..."
		else
			echo -e " 检测到 内核头 数量不正确，请检查 !" && exit 1
		fi
	fi
}

#更新引导
BBR_grub(){
	if [[ "${release}" == "centos" ]]; then
        if [[ ${version} = "6" ]]; then
            if [ ! -f "/boot/grub/grub.conf" ]; then
                echo -e "${Error} /boot/grub/grub.conf 找不到，请检查."
                exit 1
            fi
            sed -i 's/^default=.*/default=0/g' /boot/grub/grub.conf
        elif [[ ${version} = "7" ]]; then
            if [ ! -f "/boot/grub2/grub.cfg" ]; then
                echo -e "${Error} /boot/grub2/grub.cfg 找不到，请检查."
                exit 1
            fi
            grub2-set-default 0
        fi
    elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
        /usr/sbin/update-grub
    fi
}

#############内核管理组件#############



#############系统检测组件#############
#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}

#检查Linux版本
check_version(){
	if [[ -s /etc/redhat-release ]]; then
		version=`grep -oE  "[0-9.]+" /etc/redhat-release | cut -d . -f 1`
	else
		version=`grep -oE  "[0-9.]+" /etc/issue | cut -d . -f 1`
	fi
	bit=`uname -m`
	if [[ ${bit} = "x86_64" ]]; then
		bit="x64"
	else
		bit="x32"
	fi
}

#检查安装bbr的系统要求
check_sys_bbr(){
	check_version
	if [[ "${release}" == "centos" ]]; then
		if [[ ${version} -ge "6" ]]; then
			installbbr
		else
			echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	elif [[ "${release}" == "debian" ]]; then
		if [[ ${version} -ge "8" ]]; then
			installbbr
		else
			echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	elif [[ "${release}" == "ubuntu" ]]; then
		if [[ ${version} -ge "14" ]]; then
			installbbr
		else
			echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	else
		echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
	fi
}

#检查安装BBRplus新版内核的系统要求
check_sys_bbrplus(){
	check_version
	if ! command -v curl &> /dev/null; then
		echo -e "${Info} 安装curl..."
		if [[ "${release}" == "centos" ]]; then
			yum install -y curl
		elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
			apt-get update
			apt-get install -y curl
		fi
	fi
	
	if [[ "${release}" == "centos" ]]; then
		if [[ ${version} == "7" || ${version} == "8" ]]; then
			installbbrplus
		else
			echo -e "${Error} BBRplus新版内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	elif [[ "${release}" == "debian" ]]; then
		if [[ ${version} -ge "8" ]]; then
			installbbrplus
		else
			echo -e "${Error} BBRplus新版内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	elif [[ "${release}" == "ubuntu" ]]; then
		if [[ ${version} -ge "14" ]]; then
			installbbrplus
		else
			echo -e "${Error} BBRplus新版内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	else
		echo -e "${Error} BBRplus新版内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
	fi
}

#检查安装Lotsever的系统要求
check_sys_Lotsever(){
	check_version
	if [[ "${release}" == "centos" ]]; then
		if [[ ${version} == "6" ]]; then
			kernel_version="2.6.32-504"
			installlot
		elif [[ ${version} == "7" ]]; then
			yum -y install net-tools
			kernel_version="3.10.0-327"
			installlot
		else
			echo -e "${Error} Lotsever不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	elif [[ "${release}" == "debian" ]]; then
		if [[ ${version} = "7" || ${version} = "8" ]]; then
			if [[ ${bit} == "x64" ]]; then
				kernel_version="3.16.0-4"
				installlot
			elif [[ ${bit} == "x32" ]]; then
				kernel_version="3.2.0-4"
				installlot
			fi
		elif [[ ${version} = "9" ]]; then
			if [[ ${bit} == "x64" ]]; then
				kernel_version="4.9.0-4"
				installlot
			fi
		else
			echo -e "${Error} Lotsever不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	elif [[ "${release}" == "ubuntu" ]]; then
		if [[ ${version} -ge "12" ]]; then
			if [[ ${bit} == "x64" ]]; then
				kernel_version="4.8.0-36"
				installlot
			elif [[ ${bit} == "x32" ]]; then
				kernel_version="3.13.0-29"
				installlot
			fi
		else
			echo -e "${Error} Lotsever不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	else
		echo -e "${Error} Lotsever不支持当前系统 ${release} ${version} ${bit} !" && exit 1
	fi
}

check_status(){
	kernel_version=`uname -r | awk -F "-" '{print $1}'`
	kernel_version_full=`uname -r`
	if [[ ${kernel_version_full} =~ "bbrplus" ]]; then
		kernel_status="BBRplus"
	elif [[ ${kernel_version} = "3.10.0" || ${kernel_version} = "3.16.0" || ${kernel_version} = "3.2.0" || ${kernel_version} = "4.8.0" || ${kernel_version} = "3.13.0"  || ${kernel_version} = "2.6.32" || ${kernel_version} = "4.9.0" ]]; then
		kernel_status="Lotserver"
	elif [[ `echo ${kernel_version} | awk -F'.' '{print $1}'` == "4" ]] && [[ `echo ${kernel_version} | awk -F'.' '{print $2}'` -ge 9 ]] || [[ `echo ${kernel_version} | awk -F'.' '{print $1}'` -ge "5" ]]; then
		kernel_status="BBR"
	else 
		kernel_status="noinstall"
	fi

	if [[ ${kernel_status} == "Lotserver" ]]; then
		if [[ -e /appex/bin/lotServer.sh ]]; then
			run_status=`bash /appex/bin/lotServer.sh status | grep "LotServer" | awk  '{print $3}'`
			if [[ ${run_status} = "running!" ]]; then
				run_status="启动成功"
			else 
				run_status="启动失败"
			fi
		else 
			run_status="未安装加速模块"
		fi
	elif [[ ${kernel_status} == "BBR" ]]; then
		run_status=`grep "net.ipv4.tcp_congestion_control" /etc/sysctl.conf | awk -F "=" '{gsub("^[ \t]+|[ \t]+$", "", $2);print $2}'`
		if [[ ${run_status} == "bbr" ]]; then
			run_status=`lsmod | grep "bbr" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_bbr" ]]; then
				run_status="BBR启动成功"
			else 
				run_status="BBR启动失败"
			fi
		elif [[ ${run_status} == "tsunami" ]]; then
			run_status=`lsmod | grep "tsunami" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_tsunami" ]]; then
				run_status="BBR魔改版启动成功"
			else 
				run_status="BBR魔改版启动失败"
			fi
		elif [[ ${run_status} == "nanqinlang" ]]; then
			run_status=`lsmod | grep "nanqinlang" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_nanqinlang" ]]; then
				run_status="暴力BBR魔改版启动成功"
			else 
				run_status="暴力BBR魔改版启动失败"
			fi
		else 
			run_status="未安装加速模块"
		fi
	elif [[ ${kernel_status} == "BBRplus" ]]; then
		run_status=`grep "net.ipv4.tcp_congestion_control" /etc/sysctl.conf | awk -F "=" '{gsub("^[ \t]+|[ \t]+$", "", $2);print $2}'`
		if [[ ${run_status} == "bbrplus" ]]; then
			run_status=`lsmod | grep "bbrplus" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_bbrplus" ]]; then
				run_status="BBRplus启动成功"
			else 
				run_status="BBRplus启动失败"
			fi
		else 
			run_status="未安装加速模块"
		fi
	fi
}

#############系统检测组件#############
check_sys
check_version
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
start_menu

}

xrayx_install() {
#!/bin/bash
# xray一键安装脚本

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

# 以下网站是随机从Google上找到的无广告小说网站，不喜欢请改成其他网址，以http或https开头
# 搭建好后无法打开伪装域名，可能是反代小说网站挂了，请在网站留言，或者Github发issue，以便替换新的网站
SITES=(
https://oneprovide.net/aff.php?aff=179/
https://www.jjwxc.net/
https://culture.ifeng.com/
http://www.bhzwy.com/
http://book.ce.cn/
https://wap.faloo.com/
https://www.09k.net/
https://iaclouds.com/aff.php?aff=524/
http://www.bookshuku.info/
https://www.txt80.cc/
http://b.faloo.com/
https://shuqi.com/
https://www.jjwxc.net/
https://www.shukeba.com/
https://www.xiaxs.la/
https://www.shubl.com/
https://book.sfacg.com/
http://www.wzzww.com/
http://www.zongheng.com/
https://www.heiyan.com/
http://www.wjsw.com/
http://www.shuhai.com/
https://www.17k.com/
http://xs.56dyc.com/
)

CONFIG_FILE="/usr/local/etc/xray/config.json"
OS=`hostnamectl | grep -i system | cut -d: -f2`
virtual=$(systemd-detect-virt)
 kern=$(uname -r)
#  识别国家
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
v4=$(curl -s4m10 test.ipw.cn -k)
v4l=`curl -sm10 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"'`
#=====================
V6_PROXY=""
IP=$(curl -sL -4 test.ipw.cn 2>/dev/null || \
     curl -sL -4 icanhazip.com 2>/dev/null || \
     curl -sL -4 api.ipify.org 2>/dev/null || \
     curl -sL -4 ident.me 2>/dev/null || \
     curl -sL -4 ipecho.net/plain 2>/dev/null || \
     curl -sL -4 checkip.amazonaws.com 2>/dev/null || \
     curl -sL -4 bot.whatismyipaddress.com 2>/dev/null || \
     curl -sL -4 ipinfo.io/ip 2>/dev/null || \
     curl -sL -4 myexternalip.com/raw 2>/dev/null || \
     curl -sL -4 ifconfig.me 2>/dev/null || \
     curl -sL -4 wgetip.com 2>/dev/null || \
     curl -sL -4 ip.seeip.org 2>/dev/null)
if [[ -z "$IP" ]]; then
    IP=$(curl -sL -6 test.ipw.cn 2>/dev/null || \
         curl -sL -6 icanhazip.com 2>/dev/null || \
         curl -sL -6 api.ipify.org 2>/dev/null || \
         curl -sL -6 ident.me 2>/dev/null || \
         curl -sL -6 ipecho.net/plain 2>/dev/null || \
         curl -sL -6 checkip.amazonaws.com 2>/dev/null || \
         curl -sL -6 bot.whatismyipaddress.com 2>/dev/null || \
         curl -sL -6 ipinfo.io/ip 2>/dev/null || \
         curl -sL -6 myexternalip.com/raw 2>/dev/null || \
         curl -sL -6 ifconfig.me 2>/dev/null || \
         curl -sL -6 wgetip.com 2>/dev/null || \
         curl -sL -6 ip.seeip.org 2>/dev/null)
    if [[ -n "$IP" ]]; then
        V6_PROXY="https://ghfast.top/"
        echo -e "nameserver 2a01:4f8:c2c:123f::1" > /etc/resolv.conf 2>/dev/null || true
    fi
fi

BT="false"
NGINX_CONF_PATH="/etc/nginx/conf.d/"
res=`which bt 2>/dev/null`
if [[ "$res" != "" ]]; then
    BT="true"
    NGINX_CONF_PATH="/www/server/panel/vhost/nginx/"
fi

VLESS="false"
TROJAN="false"
TLS="false"
WS="false"
XTLS="false"
KCP="false"
SOCKS5="false"
REALITY="false"

checkSystem() {
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	result=$(id | awk '{print $1}')
	[[ $EUID -ne 0 ]] && colorEcho $RED " 请以root身份执行该脚本" && exit 1
	res=$(which yum 2>/dev/null)
	if [[ "$?" != "0" ]]; then
		res=$(which dnf 2>/dev/null)
		if [[ "$?" != "0" ]]; then
			res=$(which apt 2>/dev/null)
			if [[ "$?" != "0" ]]; then
				colorEcho $RED " 不受支持的Linux系统"
				exit 1
			fi
			PMT="apt"
			CMD_INSTALL="apt install -y "
			CMD_REMOVE="apt remove -y "
			CMD_UPGRADE="apt update; apt upgrade -y; apt autoremove -y"
		else
			PMT="dnf"
			CMD_INSTALL="dnf install -y "
			CMD_REMOVE="dnf remove -y "
			CMD_UPGRADE="dnf update -y"
		fi
	else
		PMT="yum"
		CMD_INSTALL="yum install -y "
		CMD_REMOVE="yum remove -y "
		CMD_UPGRADE="yum update -y"
	fi
	
	res=$(which systemctl 2>/dev/null)
	if [[ "$?" != "0" ]]; then
		colorEcho $RED " 系统版本过低，请升级到最新版本"
		exit 1
    fi    
}

colorEcho() {
    echo -e "${1}${@:2}${PLAIN}"
}

configNeedNginx() {
    local ws=`grep wsSettings $CONFIG_FILE`
    if [[ -z "$ws" ]]; then
        echo no
        return
    fi
    echo yes
}

needNginx() {
    if [[ "$WS" = "false" ]]; then
        echo no
        return
    fi
    echo yes
}

status() {
    if [[ ! -f /usr/local/bin/xray ]]; then
        echo 0
        return
    fi
    if [[ ! -f $CONFIG_FILE ]]; then
        echo 1
        return
    fi
    port=`grep port $CONFIG_FILE| head -n 1| cut -d: -f2| tr -d \",' '`
    res=`ss -nutlp| grep ${port} | grep -i xray`
    if [[ -z "$res" ]]; then
        echo 2
        return
    fi

    if [[ `configNeedNginx` != "yes" ]]; then
        echo 3
    else
        res=`ss -nutlp|grep -i nginx`
        if [[ -z "$res" ]]; then
            echo 4
        else
            echo 5
        fi
    fi
}

statusText() {
    res=`status`
    case $res in
        2) echo -e ${GREEN}已安装${PLAIN} ${RED}未运行${PLAIN} ;;
        3) echo -e ${GREEN}已安装${PLAIN} ${GREEN}Xray正在运行${PLAIN} ;;
        4) echo -e ${GREEN}已安装${PLAIN} ${GREEN}Xray正在运行${PLAIN}, ${RED}Nginx未运行${PLAIN} ;;
        5) echo -e ${GREEN}已安装${PLAIN} ${GREEN}Xray正在运行, Nginx正在运行${PLAIN} ;;
        *) echo -e ${RED}未安装${PLAIN} ;;
    esac
}

normalizeVersion() {
    if [ -n "$1" ]; then
        case "$1" in
            v*)
                echo "$1"
            ;;
            http*)
                echo "v26.2.6"
            ;;
            *)
                echo "v$1"
            ;;
        esac
    else
        echo ""
    fi
}

# 1: 新Xray。0: 否。1: 是。2: 未安装。3: 检查失败。
getVersion() {
    VER=`/usr/local/bin/xray version|head -n1 | awk '{print $2}'`
    RETVAL=$?
    CUR_VER="$(normalizeVersion "$(echo "$VER" | head -n 1 | cut -d " " -f2)")"
    TAG_URL="https://api.github.com/repos/XTLS/Xray-core/releases/latest"
    NEW_VER="$(normalizeVersion "$(curl -s "${TAG_URL}" --connect-timeout 10 | grep '"tag_name":' | cut -d'"' -f4)")"
    # 解决通过Github API获取xray最新版本失败问题
    if [[ $NEW_VER == "" ]]; then
        NEW_VER=v$1
    fi	
    if [[ "$XTLS" = "true" ]]; then
        NEW_VER=v1.7.5
    fi
    if [[ $? -ne 0 ]] || [[ $NEW_VER == "" ]]; then
        colorEcho $RED " 检查Xray版本信息失败，请检查网络"
        return 3
    elif [[ $RETVAL -ne 0 ]];then
        return 2
    elif [[ $NEW_VER != $CUR_VER ]];then
        return 1
    fi
    return 0
}

archAffix() {
	case "$(uname -m)" in
	i686 | i386) echo '32' ;;
	x86_64 | amd64) echo '64' ;;
	armv5tel) echo 'arm32-v5' ;;
	armv6l) echo 'arm32-v6' ;;
	armv7 | armv7l) echo 'arm32-v7a' ;;
	armv8 | aarch64) echo 'arm64-v8a' ;;
	mips64le) echo 'mips64le' ;;
	mips64) echo 'mips64' ;;
	mipsle) echo 'mips32le' ;;
	mips) echo 'mips32' ;;
	ppc64le) echo 'ppc64le' ;;
	ppc64) echo 'ppc64' ;;
	ppc64le) echo 'ppc64le' ;;
	riscv64) echo 'riscv64' ;;
	s390x) echo 's390x' ;;
	*) red " 不支持的CPU架构！" && exit 1 ;;
	esac

	return 0
}

getData() {
 mkdir -p /usr/local/etc/xray
    if [[ "$REALITY" = "true" ]]; then
        echo ""
        echo " Xray Reality 配置，无需域名和证书"
        echo " 生成Reality密钥对..."
        if command -v openssl &> /dev/null; then
            SHORT_IDS=("$(openssl rand -hex 8)" "$(openssl rand -hex 8)" "$(openssl rand -hex 8)")
            SELECTED_SHORT_ID=${SHORT_IDS[0]}
        else
            colorEcho $RED " openssl未安装，无法生成密钥对"
            exit 1
        fi
        REALITY_DESTINATIONS=(
            "learn.microsoft.com:443"
            "www.apple.com:443"
            "www.google.com:443" 
            "www.microsoft.com:443"
            "chat.openai.com:443"
            "github.com:443"
            "www.amazon.com:443"
        )
        echo ""
        colorEcho $BLUE " 请选择 Reality 伪装目标:"
        for i in "${!REALITY_DESTINATIONS[@]}"; do
            echo "   $((i+1))) ${REALITY_DESTINATIONS[$i]}"
        done
        read -p "  请选择[默认:1]:" answer
        case $answer in
            2) REALITY_DEST="${REALITY_DESTINATIONS[1]}" ;;
            3) REALITY_DEST="${REALITY_DESTINATIONS[2]}" ;;
            4) REALITY_DEST="${REALITY_DESTINATIONS[3]}" ;;
            5) REALITY_DEST="${REALITY_DESTINATIONS[4]}" ;;
            6) REALITY_DEST="${REALITY_DESTINATIONS[5]}" ;;
            *) REALITY_DEST="${REALITY_DESTINATIONS[0]}" ;;
        esac
        REALITY_SERVER_NAME=$(echo $REALITY_DEST | cut -d: -f1)
        colorEcho $BLUE " 伪装目标: $REALITY_DEST"
        colorEcho $BLUE " ShortId: $SELECTED_SHORT_ID"
        colorEcho $YELLOW " 公钥将在安装Xray后生成"   
        read -p " 请输入Reality监听端口[默认1000-65535之间的数字]：" PORT
        [[ -z "${PORT}" ]] && PORT=$(shuf -i2000-65000 -n1)
        if [[ "${PORT:0:1}" = "0" ]]; then
            colorEcho ${RED} " 端口不能以0开头"
            exit 1
        fi
        colorEcho ${BLUE} " Reality 端口：$PORT"
        return 0
    fi
    if [[ "$TLS" = "true" || "$XTLS" = "true" ]]; then
        echo ""
        echo " Xray一键脚本，运行之前请确认如下条件已经具备："
        colorEcho ${YELLOW} "  1. 一个伪装域名"
        colorEcho ${YELLOW} "  2. 伪装域名DNS解析指向当前服务器ip（${IP}）"
        colorEcho ${BLUE} "    3. 如果/root目录下有  ${GREEN}xray.pem${PLAIN} 和 ${GREEN}xray.key${PLAIN} 证书密钥文件，无需理会条件2"
		colorEcho ${YELLOW} "  4. 请确保Cloudflare小云朵为关闭状态(仅限DNS)，其他域名解析网站设置同理"
		colorEcho ${YELLOW} "  5. 请检查DNS解析设置的IP是否为VPS的IP"        
        echo " "
            read -p " 请输入伪装域名：" DOMAIN
            if [[ -z "${DOMAIN}" ]]; then
                colorEcho ${RED} " 域名输入错误，请重新输入！"
               getData
            fi
        DOMAIN=${DOMAIN,,}
        colorEcho ${BLUE}  " 伪装域名(host)：$DOMAIN"
        echo ""
        if [[ -f ~/xray.pem && -f ~/xray.key ]]; then
            colorEcho ${BLUE}  " 检测到自有证书，将使用其部署"
            CERT_FILE="/usr/local/etc/xray/${DOMAIN}.pem"
            KEY_FILE="/usr/local/etc/xray/${DOMAIN}.key"
        else
	    resolve=$(curl -sH "accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=${DOMAIN}&type=A" && \
          	      curl -sH "accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=${DOMAIN}&type=AAAA")
            res=`echo -n ${resolve} | grep ${IP}`
            if [[ -z "${res}" ]]; then
                colorEcho ${BLUE}  "${DOMAIN} 解析结果：${resolve}"
                colorEcho "${YELLOW}$DOMAIN ${PLAIN}${PLAIN}域名${PLAIN}${RED}未解析到当前服务器IP${PLAIN}${YELLOW}(${IP})${PLAIN}!"
                exit 1
        else
                colorEcho "${YELLOW}$DOMAIN ${PLAIN}${PLAIN}域名${PLAIN}${GREEN}已解析到当前服务器IP${YELLOW}(${IP})${PLAIN}。${PLAIN}"
            fi
        fi
    fi
echo ""
if [[ "$SOCKS5" = "true" ]]; then
        read -t 5 -p " 请输入SOCKS5端口[默认1000-65535之间的数字]：" PORT
        [[ -z "${PORT}" ]] && PORT=$(shuf -i2000-65000 -n1)
        if [[ "${PORT:0:1}" = "0" ]]; then
            colorEcho ${RED} " 端口不能以0开头"
            exit 1
        fi
        colorEcho ${BLUE} " SOCKS5 端口：$PORT" 
    elif [[ "$(needNginx)" == "no" ]]; then
        if [[ "$TLS" == "true" ]]; then
            read -p " 请输入xray监听端口[默认100-65535之间的数字]：" PORT
            [[ -z "${PORT}" ]] && PORT=$(shuf -i2000-65000 -n1)
        else
            read -p " 请输入xray监听端口[100-65535之间的数字]：" PORT
            [[ -z "${PORT}" ]] && PORT=$(shuf -i2000-65000 -n1)
            if [[ "${PORT:0:1}" == "0" ]]; then
                colorEcho ${RED} " 端口不能以0开头"
                exit 1
            fi
        fi
        colorEcho ${BLUE} " xray端口：$PORT"
    else
        read -p " 请输入Nginx监听端口[默认100-65535之间的数字]：" PORT
        [[ -z "${PORT}" ]] && PORT=$(shuf -i2000-65000 -n1)
        [ "${PORT:0:1}" = "0" ] && colorEcho ${BLUE} " 端口不能以0开头" && exit 1
        colorEcho ${BLUE} " Nginx端口：$PORT"
        XPORT=$(shuf -i2000-65000 -n1)
    fi
	if [[ "$KCP" == "true" ]]; then
		echo ""
		yellow "请选择伪装类型："
		echo "   1) 无"
		echo "   2) BT下载"
		echo "   3) 视频通话"
		echo "   4) 微信视频通话"
		echo "   5) dtls"
		echo "   6) wiregard"
		read -p "请选择伪装类型[默认：无]：" answer
		case $answer in
		2) HEADER_TYPE="utp" ;;
		3) HEADER_TYPE="srtp" ;;
		4) HEADER_TYPE="wechat-video" ;;
		5) HEADER_TYPE="dtls" ;;
		6) HEADER_TYPE="wireguard" ;;
		*) HEADER_TYPE="none" ;;
		esac
		yellow "伪装类型：$HEADER_TYPE"
		SEED=$(cat /proc/sys/kernel/random/uuid)
	fi
	if [[ "$TROJAN" == "true" ]]; then
		echo ""
		read -p "请设置trojan密码（不输则随机生成）:" PASSWORD
		[[ -z "$PASSWORD" ]] && PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
		yellow " trojan密码：$PASSWORD"
	fi
	if [[ "$XTLS" == "true" ]]; then
		echo ""
        colorEcho $BLUE " 请选择流控模式:" 
        echo -e "   1) xtls-rprx-direct [$RED推荐$PLAIN]"
        echo "   2) xtls-rprx-origin"
        read -p "  请选择流控模式[默认:direct]" answer
        [[ -z "$answer" ]] && answer=1
        case $answer in
            1)
                FLOW="xtls-rprx-direct"
                ;;
            2)
                FLOW="xtls-rprx-origin"
                ;;
            *)
                colorEcho $RED " 无效选项，使用默认的xtls-rprx-direct"
                FLOW="xtls-rprx-direct"
                ;;
        esac
        colorEcho $BLUE " 流控模式：$FLOW"
    fi

    if [[ "${WS}" = "true" ]]; then
        echo ""
        while true
        do
            read -p " 请输入伪装路径，以/开头(不懂请直接回车)：" WSPATH
            if [[ -z "${WSPATH}" ]]; then
                len=`shuf -i12-18 -n1`
                ws=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $len | head -n 1`
                WSPATH="/$ws"
                break
            elif [[ "${WSPATH:0:1}" != "/" ]]; then
                colorEcho ${RED}  " 伪装路径必须以/开头！"
            elif [[ "${WSPATH}" = "/" ]]; then
                colorEcho ${RED}   " 不能使用根路径！"
            else
                break
            fi
        done
        colorEcho ${BLUE}  " ws路径：$WSPATH"
    fi

    if [[ "$TLS" = "true" || "$XTLS" = "true" ]]; then
        echo ""
        colorEcho $BLUE " 请选择伪装站类型:"
    	echo "   1) 静态网站：小白不建议使用这个(位于/usr/share/nginx/html)"
		echo "   2) 34个小说站(随机)"
        echo "   3) 美女站1(https://www.jp94.com)"
        echo "   4) 美女站2(https://www.1jiepai.com)"				
        echo "   5) 世嘉maimai站(https://maimai.sega.jp)"
		echo "   6) 高清壁纸站1(https://bing.ioliu.cn)"
		echo "   7) 高清壁纸站2(https://wallhaven.cc)"
		echo "   8) 自定义反代站点(需以http或者https开头)"
		echo		
		read -p " 请选择伪装网站类型[默认:34个小说站(随机选择一个)]" answer
		if [[ -z "$answer" ]]; then
                len=${#SITES[@]}
                ((len--))
                index=$(shuf -i0-$len -n 1)
                PROXY_URL=${SITES[$index]}			
		else
			case $answer in
				1) PROXY_URL="" 
				;;
				2)
					len=${#SITES[@]}
					((len--))
					while true; do
						index=$(shuf -i0-${len} -n1)
						PROXY_URL=${SITES[$index]}
						host=$(echo ${PROXY_URL} | cut -d/ -f3)
						ip=$(curl -sL http://ip-api.com/json/${host})
						res=$(echo -n ${ip} | grep ${host})
						if [[ "${res}" == "" ]]; then
							echo "$ip $host" >>/etc/hosts
							break
						fi
					done
					;;
				3) PROXY_URL="https://www.jp94.com" ;;
				4) PROXY_URL="https://www.1jiepai.com" ;;
                5) PROXY_URL="https://maimai.sega.jp" ;;
				6) PROXY_URL="https://bing.ioliu.cn" ;;
				7) PROXY_URL="https://wallhaven.cc" ;;				
				8)
					read -p " 请输入反代站点(以http或者https开头)：" PROXY_URL
					if [[ -z "$PROXY_URL" ]]; then
						colorEcho $RED " 请输入反代网站！"
						exit 1
					elif [[ "${PROXY_URL:0:4}" != "http" ]]; then
						colorEcho $RED " 反代网站必须以http或https开头！"
						exit 1
					fi
					;;
            *)
                colorEcho $RED " 请输入正确的选项！"
                exit 1
            esac
        fi
        REMOTE_HOST=`echo ${PROXY_URL} | cut -d/ -f3`
        colorEcho $BLUE " 伪装网站：$PROXY_URL"
echo ""
yellow "是否允许搜索引擎爬取网站？[默认：不允许]"
echo "   y)允许，会有更多ip请求网站，但会消耗一些流量，vps流量充足情况下推荐使用"
echo "   n)不允许，爬虫不会访问网站，访问ip比较单一，但能节省vps流量"
# 跳过用户交互，直接设置为不允许
ALLOW_SPIDER="n"
echo ""
yellow "允许搜索引擎：$ALLOW_SPIDER"
        fi
}

installNginx() {
    echo ""
    colorEcho $BLUE " 安装nginx..."
    if [[ "$BT" = "false" ]]; then
        if [[ "$PMT" = "yum" ]]; then
            $CMD_INSTALL epel-release
            if [[ "$?" != "0" ]]; then
                echo '[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true' > /etc/yum.repos.d/nginx.repo
            fi
        fi
        $CMD_INSTALL nginx
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " Nginx安装失败，请到 https://hijk.art 反馈"
            exit 1
        fi
        systemctl enable nginx
    else
        res=`which nginx 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " 您安装了宝塔，请在宝塔后台安装nginx后再运行本脚本"
            exit 1
        fi
    fi
}

startNginx() {
    if [[ "$BT" = "false" ]]; then
        systemctl start nginx
    else
        nginx -c /www/server/nginx/conf/nginx.conf
    fi
}

stopNginx() {
    if [[ "$BT" = "false" ]]; then
        systemctl stop nginx
    else
        res=`ps aux | grep -i nginx`
        if [[ "$res" != "" ]]; then
            nginx -s stop
        fi
    fi
}

getCert() {
	mkdir -p /usr/local/etc/xray
	if [[ -z ${CERT_FILE+x} ]]; then
		stopNginx
		systemctl stop xray
        for port in 80 443; do
            if [[ 0 -eq $(lsof -i:"$port" | grep -i -c "listen") ]]; then
                colorEcho "${OK} ${GreenBG} $port $(gettext "端口未被占用") ${Font}"
            else
                colorEcho "${Error} ${RedBG} $(gettext "检测到") $port $(gettext "端口被占用"), $(gettext "以下为") $port $(gettext "端口占用信息") ${Font}"
                lsof -i:"$port"
                echo "$(gettext "尝试终止占用的进程")!"
                lsof -i:"$port" | awk '{print $2}' | grep -v "PID" | xargs kill -9
                colorEcho "${OK} ${GreenBG} $port $(gettext "端口清理完成") ${Font}"
            fi
        done
        $CMD_INSTALL socat openssl
        if [[ "$PMT" = "yum" ]]; then
            $CMD_INSTALL cronie
            systemctl start crond
            systemctl enable crond
        else
            $CMD_INSTALL cron
            systemctl start cron
            systemctl enable cron
        fi
        curl -sL https://get.acme.sh | sh -s email=hijk.pw@protonmail.sh
        source ~/.bashrc
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [[ "$BT" = "false" ]]; then
            ~/.acme.sh/acme.sh --issue -d $DOMAIN --keylength ec-256 --pre-hook "systemctl stop nginx" --post-hook "systemctl restart nginx" --standalone
        else
            ~/.acme.sh/acme.sh --issue -d $DOMAIN --keylength ec-256 --pre-hook "nginx -s stop || { echo -n ''; }" --post-hook "nginx -c /www/server/nginx/conf/nginx.conf || { echo -n ''; }" --standalone
        fi
        [[ -f ~/.acme.sh/${DOMAIN}_ecc/ca.cer ]] || {
            colorEcho $RED "获取证书失败，请复制上面的红色文字到 https://hijk.art 反馈"
            exit 1
        }
        CERT_FILE="/usr/local/etc/xray/${DOMAIN}.pem"
        KEY_FILE="/usr/local/etc/xray/${DOMAIN}.key"
        ~/.acme.sh/acme.sh --install-cert -d $DOMAIN --ecc \
            --key-file       $KEY_FILE \
            --fullchain-file $CERT_FILE \
            --reloadcmd     "service nginx force-reload"
        [[ -f $CERT_FILE && -f $KEY_FILE ]] || {
            colorEcho $RED "获取证书失败，请到 https://hijk.art 反馈"
            exit 1
        }
    else
        cp ~/xray.pem /usr/local/etc/xray/${DOMAIN}.pem
        cp ~/xray.key /usr/local/etc/xray/${DOMAIN}.key
    fi
}

configNginx() {
    mkdir -p /usr/share/nginx/html;
    if [[ "$ALLOW_SPIDER" = "n" ]]; then
        echo 'User-Agent: *' > /usr/share/nginx/html/robots.txt
        echo 'Disallow: /' >> /usr/share/nginx/html/robots.txt
        ROBOT_CONFIG="    location = /robots.txt {}"
    else
        ROBOT_CONFIG=""
    fi

    if [[ "$BT" = "false" ]]; then
        if [[ ! -f /etc/nginx/nginx.conf.bak ]]; then
            mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
        fi
        res=`id nginx 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            user="www-data"
        else
            user="nginx"
        fi
        cat > /etc/nginx/nginx.conf<<-EOF
user $user;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    server_tokens off;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    gzip                on;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
}
EOF
    fi

    if [[ "$PROXY_URL" = "" ]]; then
        action=""
    else
        action="proxy_ssl_server_name on;
        proxy_pass $PROXY_URL;
        proxy_set_header Accept-Encoding '';
        sub_filter \"$REMOTE_HOST\" \"$DOMAIN\";
        sub_filter_once off;"
    fi

    if [[ "$TLS" = "true" || "$XTLS" = "true" ]]; then
        mkdir -p ${NGINX_CONF_PATH}
        # VMESS+WS+TLS
        # VLESS+WS+TLS
        if [[ "$WS" = "true" ]]; then
            cat > ${NGINX_CONF_PATH}${DOMAIN}.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};
    return 301 https://\$server_name:${PORT}\$request_uri;
}

server {
    listen       ${PORT} ssl http2;
    listen       [::]:${PORT} ssl http2;
    server_name ${DOMAIN};
    charset utf-8;

    # ssl配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
	ssl_ecdh_curve secp384r1;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    ssl_certificate $CERT_FILE;
    ssl_certificate_key $KEY_FILE;

    root /usr/share/nginx/html;
    location / {
        $action
    }
    $ROBOT_CONFIG

    location ${WSPATH} {
      proxy_redirect off;
      proxy_pass http://127.0.0.1:${XPORT};
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
        else
            # VLESS+TCP+TLS
            # VLESS+TCP+XTLS
            # trojan
            cat > ${NGINX_CONF_PATH}${DOMAIN}.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    listen 81 http2;
    server_name ${DOMAIN};
    root /usr/share/nginx/html;
    location / {
        $action
    }
    $ROBOT_CONFIG
}
EOF
        fi
    fi
}

setSelinux() {
    if [[ -s /etc/selinux/config ]] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
        setenforce 0
    fi
}

setFirewall() {
    res=`which firewall-cmd 2>/dev/null`
    if [[ $? -eq 0 ]]; then
        systemctl status firewalld > /dev/null 2>&1
        if [[ $? -eq 0 ]];then
            firewall-cmd --permanent --add-service=http
            firewall-cmd --permanent --add-service=https
            if [[ "$PORT" != "443" ]]; then
                firewall-cmd --permanent --add-port=${PORT}/tcp
                firewall-cmd --permanent --add-port=${PORT}/udp
            fi
            firewall-cmd --reload
        else
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport 80 -j ACCEPT
                iptables -I INPUT -p tcp --dport 443 -j ACCEPT
                if [[ "$PORT" != "443" ]]; then
                    iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                    iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
                fi
            fi
        fi
    else
        res=`which iptables 2>/dev/null`
        if [[ $? -eq 0 ]]; then
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport 80 -j ACCEPT
                iptables -I INPUT -p tcp --dport 443 -j ACCEPT
                if [[ "$PORT" != "443" ]]; then
                    iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                    iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
                fi
            fi
        else
            res=`which ufw 2>/dev/null`
            if [[ $? -eq 0 ]]; then
                res=`ufw status | grep -i inactive`
                if [[ "$res" = "" ]]; then
                    ufw allow http/tcp
                    ufw allow https/tcp
                    if [[ "$PORT" != "443" ]]; then
                        ufw allow ${PORT}/tcp
                        ufw allow ${PORT}/udp
                    fi
                fi
            fi
        fi
    fi
}

installXray() {
    rm -rf /tmp/xray
    mkdir -p /tmp/xray
    DOWNLOAD_LINK="${V6_PROXY}https://github.com/XTLS/Xray-core/releases/download/${NEW_VER}/Xray-linux-$(archAffix).zip"
    colorEcho $BLUE " 下载Xray: ${DOWNLOAD_LINK}"
    curl -L -H "Cache-Control: no-cache" -o /tmp/xray/xray.zip ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        colorEcho $RED " 下载Xray文件失败，请检查服务器网络设置"
        exit 1
    fi
    systemctl stop xray
    mkdir -p /usr/local/etc/xray /usr/local/share/xray && \
    unzip /tmp/xray/xray.zip -d /tmp/xray
    cp /tmp/xray/xray /usr/local/bin
    cp /tmp/xray/geo* /usr/local/share/xray
    chmod +x /usr/local/bin/xray || {
        colorEcho $RED " Xray安装失败"
        exit 1
    }

    cat >/etc/systemd/system/xray.service<<-EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable xray.service
}

trojanConfig() {
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "trojan",
    "settings": {
      "clients": [
        {
          "password": "$PASSWORD"
        }
      ],
      "fallbacks": [
        {
              "alpn": "http/1.1",
              "dest": 80
          },
          {
              "alpn": "h2",
              "dest": 81
          }
      ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
            "serverName": "$DOMAIN",
            "alpn": ["http/1.1", "h2"],
            "certificates": [
                {
                    "certificateFile": "$CERT_FILE",
                    "keyFile": "$KEY_FILE"
                }
            ]
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

trojanXTLSConfig() {
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "trojan",
    "settings": {
      "clients": [
        {
          "password": "$PASSWORD",
          "flow": "$FLOW"
        }
      ],
      "fallbacks": [
        {
              "alpn": "http/1.1",
              "dest": 80
          },
          {
              "alpn": "h2",
              "dest": 81
          }
      ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
            "serverName": "$DOMAIN",
            "alpn": ["http/1.1", "h2"],
            "certificates": [
                {
                    "certificateFile": "$CERT_FILE",
                    "keyFile": "$KEY_FILE"
                }
            ]
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vmessConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 1,
          "alterId": 0
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vmessKCPConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 1,
          "alterId": $0
        }
      ]
    },
    "streamSettings": {
        "network": "mkcp",
        "kcpSettings": {
            "uplinkCapacity": 100,
            "downlinkCapacity": 100,
            "congestion": true,
            "header": {
                "type": "$HEADER_TYPE"
            },
            "seed": "$SEED"
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vmessTLSConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 1,
          "alterId": 0
        }
      ],
      "disableInsecureEncryption": false
    },
    "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
            "serverName": "$DOMAIN",
            "alpn": ["http/1.1", "h2"],
            "certificates": [
                {
                    "certificateFile": "$CERT_FILE",
                    "keyFile": "$KEY_FILE"
                }
            ]
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vmessWSConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $XPORT,
    "listen": "127.0.0.1",
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 1,
          "alterId": 0
        }
      ],
      "disableInsecureEncryption": false
    },
    "streamSettings": {
        "network": "ws",
        "wsSettings": {
            "path": "$WSPATH",
            "headers": {
                "Host": "$DOMAIN"
            }
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vlessTCPConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vless",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 0
        }
      ],
      "decryption": "none"
    },
    "streamSettings": {
        "network": "tcp",
        "security": "none"
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vlessTLSConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vless",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 0
        }
      ],
      "decryption": "none",
      "fallbacks": [
          {
              "alpn": "http/1.1",
              "dest": 80
          },
          {
              "alpn": "h2",
              "dest": 81
          }
      ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
            "serverName": "$DOMAIN",
            "alpn": ["http/1.1", "h2"],
            "certificates": [
                {
                    "certificateFile": "$CERT_FILE",
                    "keyFile": "$KEY_FILE"
                }
            ]
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vlessXTLSConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vless",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "flow": "$FLOW",
          "level": 0
        }
      ],
      "decryption": "none",
      "fallbacks": [
          {
              "alpn": "http/1.1",
              "dest": 80
          },
          {
              "alpn": "h2",
              "dest": 81
          }
      ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
            "serverName": "$DOMAIN",
            "alpn": ["http/1.1", "h2"],
            "certificates": [
                {
                    "certificateFile": "$CERT_FILE",
                    "keyFile": "$KEY_FILE"
                }
            ]
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vlessWSConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $XPORT,
    "listen": "127.0.0.1",
    "protocol": "vless",
    "settings": {
        "clients": [
            {
                "id": "$uuid",
                "level": 0
            }
        ],
        "decryption": "none"
    },
    "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
            "path": "$WSPATH",
            "headers": {
                "Host": "$DOMAIN"
            }
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vlessKCPConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vless",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 0
        }
      ],
      "decryption": "none"
    },
    "streamSettings": {
        "streamSettings": {
            "network": "mkcp",
            "kcpSettings": {
                "uplinkCapacity": 100,
                "downlinkCapacity": 100,
                "congestion": true,
                "header": {
                    "type": "$HEADER_TYPE"
                },
                "seed": "$SEED"
            }
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

socks5Config() {
    user=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n1)
    password=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n1)
    cat > $CONFIG_FILE <<-EOF
{
  "inbounds": [{
    "port": ${PORT},
    "protocol": "socks",
    "settings": {
      "auth": "password",
      "accounts": [
        {"user": "${user}", "pass": "${password}"}
      ],
      "udp": true,
      "ip": "0.0.0.0"
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF
}

realityConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "$REALITY_DEST",
          "xver": 0,
          "serverNames": [
            "$REALITY_SERVER_NAME"
          ],
          "privateKey": "$private_key",
          "publicKey": "$public_key",
          "shortIds": [
            "$SELECTED_SHORT_ID"
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIPv4v6"
      }
    }
  ]

}
EOF
}

configXray() {
    mkdir -p /usr/local/xray
    if [[ "$SOCKS5" = "true" ]]; then
        socks5Config
        return 0
    fi
    if [[ "$REALITY" = "true" ]]; then
        realityConfig
        return 0
    fi
    if [[ "$TROJAN" = "true" ]]; then
        if [[ "$XTLS" = "true" ]]; then
            trojanXTLSConfig
        else
            trojanConfig
        fi
        return 0
    fi
    if [[ "$VLESS" = "false" ]]; then
        # VMESS + kcp
        if [[ "$KCP" = "true" ]]; then
            vmessKCPConfig
            return 0
        fi
        # VMESS
        if [[ "$TLS" = "false" ]]; then
            vmessConfig
        elif [[ "$WS" = "false" ]]; then
            # VMESS+TCP+TLS
            vmessTLSConfig
        # VMESS+WS+TLS
        else
            vmessWSConfig
        fi
    #VLESS
    else
        if [[ "$KCP" = "true" ]]; then
            vlessKCPConfig
            return 0
        fi
        # VLESS+TCP（无TLS）
        if [[ "$TLS" = "false" && "$WS" = "false" ]]; then
            vlessTCPConfig
        # VLESS+TCP+TLS 或 VLESS+TCP+XTLS
        elif [[ "$WS" = "false" ]]; then
            if [[ "$XTLS" = "false" ]]; then
                vlessTLSConfig
            else
                vlessXTLSConfig
            fi
        # VLESS+WS+TLS
        else
            vlessWSConfig
        fi
    fi
}

install() {
    getData

    $PMT clean all
    [[ "$PMT" = "apt" ]] && $PMT update
    $CMD_INSTALL wget vim unzip tar gcc openssl curl jp
    $CMD_INSTALL ruby qrencode psmisc sudo vim curl
    $CMD_INSTALL libqrencode libqrencode-dev --fix-broken
    $CMD_INSTALL net-tools firewalld iptables ufw
    if [[ "$PMT" = "apt" ]]; then
        $CMD_INSTALL libssl-dev g++
    fi
    res=`which unzip 2>/dev/null`
    if [[ $? -ne 0 ]]; then
        colorEcho $RED " unzip安装失败，请检查网络"
        exit 1
    fi
    if [[ "$(needNginx)" = "yes" ]] || [[ "$TLS" = "true" ]] || [[ "$XTLS" = "true" ]]; then
        installNginx
    fi
    setFirewall
    if [[ "$TLS" = "true" || "$XTLS" = "true" ]]; then
        getCert
        configNginx
    fi
    colorEcho $BLUE " 安装Xray..."
    getVersion
    RETVAL="$?"
    if [[ $RETVAL == 0 ]]; then
        colorEcho $BLUE " Xray最新版 ${CUR_VER} 已经安装"
    elif [[ $RETVAL == 3 ]]; then
        exit 1
    else
        colorEcho $BLUE " 安装Xray ${NEW_VER} ，架构$(archAffix)"
        installXray
    fi
if [[ "$REALITY" = "true" ]]; then
        colorEcho $BLUE " 生成Reality密钥对..."
        if [[ -f /usr/local/bin/xray ]]; then
        # 生成密钥对
        key_pair=$(/usr/local/bin/xray x25519)
        private_key=$(echo "$key_pair" | awk '/PrivateKey:/ {print $2}')
        public_key=$(echo "$key_pair" | awk '/Public key:/ {print $2}')
        public_key=$(echo "$key_pair" | awk '/Password:/ {print $2}')
# 保存密钥对到文件
        mkdir -p /usr/local/etc/xray
        echo "$private_key" > /usr/local/etc/xray/reality_private.key
        echo "$public_key" > /usr/local/etc/xray/reality_public.key
        colorEcho $GREEN " 私钥生成成功: $private_key"
        colorEcho $GREEN " 公钥生成成功: $public_key"
        colorEcho $BLUE " 密钥已保存到: /usr/local/etc/xray/reality_*.key"
        # 设置权限
        chmod 600 /usr/local/etc/xray/reality_*.key
    else
        colorEcho $RED " Xray安装失败，无法生成密钥对"
        exit 1
    fi
fi	
	configXray
	setSelinux
	start
	showInfo
}

#启动nginx
nginx() {
systemctl start nginx
}

#重启nginx
nginx2() {
systemctl restart nginx
}

update() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        colorEcho $RED " Xray未安装，请先安装！"
        return
    fi

    getVersion
    RETVAL="$?"
    if [[ $RETVAL == 0 ]]; then
        colorEcho $BLUE " Xray最新版 ${CUR_VER} 已经安装"
    elif [[ $RETVAL == 3 ]]; then
        exit 1
    else
        colorEcho $BLUE " 安装Xray ${NEW_VER} ，架构$(archAffix)"
        installXray
        stop
        start

        colorEcho $GREEN " 最新版Xray安装成功！"
    fi
}

uninstall() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        colorEcho $RED " Xray未安装，请先安装！"
        return
    fi

    echo ""
    read -p " 确定卸载Xray？[y/n]：" answer
    if [[ "${answer,,}" = "y" ]]; then
        domain=`grep Host $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
        if [[ "$domain" = "" ]]; then
            domain=`grep serverName $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
        fi
        
        stop
        systemctl disable xray
        rm -rf /etc/systemd/system/xray.service
        rm -rf /usr/local/bin/xray
        rm -rf /usr/local/etc/xray
        rm -rf /root/.acme.sh
        if [[ "$BT" = "false" ]]; then
            systemctl disable nginx
            $CMD_REMOVE nginx
            if [[ "$PMT" = "apt" ]]; then
                $CMD_REMOVE nginx-common
            fi
            rm -rf /etc/nginx/nginx.conf
            if [[ -f /etc/nginx/nginx.conf.bak ]]; then
                mv /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf
            fi
        fi
        if [[ "$domain" != "" ]]; then
            rm -rf ${NGINX_CONF_PATH}${domain}.conf
        fi
        [[ -f ~/.acme.sh/acme.sh ]] && ~/.acme.sh/acme.sh --uninstall
        colorEcho $GREEN " Xray卸载成功"
    fi
}

start() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        colorEcho $RED " Xray未安装，请先安装！"
        return
    fi
    stopNginx
    startNginx
    systemctl restart xray
    sleep 2
    
    port=`grep port $CONFIG_FILE| head -n 1| cut -d: -f2| tr -d \",' '`
    res=`ss -nutlp| grep ${port} | grep -i xray`
    if [[ "$res" = "" ]]; then
        colorEcho $RED " Xray启动失败，请检查日志或查看端口是否被占用！"
    else
        colorEcho $BLUE " Xray启动成功"
    fi
}

stop() {
    stopNginx
    systemctl stop xray
    colorEcho $BLUE " Xray停止成功"
}


restart() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        colorEcho $RED " Xray未安装，请先安装！"
        return
    fi

    stop
    start
}


getConfigFileInfo() {
    vless="false"
    tls="false"
    ws="false"
    xtls="false"
    trojan="false"
    protocol="VMess"
    kcp="false"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        return
    fi
    
    uid=`grep id $CONFIG_FILE 2>/dev/null | head -n1| cut -d: -f2 | tr -d \",' '`
    alterid=`grep alterId $CONFIG_FILE 2>/dev/null | cut -d: -f2 | tr -d \",' '`
    network=`grep network $CONFIG_FILE 2>/dev/null | tail -n1| cut -d: -f2 | tr -d \",' '`
    [[ -z "$network" ]] && network="tcp"
    domain=`grep serverName $CONFIG_FILE 2>/dev/null | cut -d: -f2 | tr -d \",' '`
    if [[ "$domain" = "" ]]; then
        domain=`grep Host $CONFIG_FILE 2>/dev/null | cut -d: -f2 | tr -d \",' '`
        if [[ "$domain" != "" ]]; then
            ws="true"
            tls="true"
            wspath=`grep path $CONFIG_FILE 2>/dev/null | cut -d: -f2 | tr -d \",' '`
        fi
    else
        tls="true"
    fi
    if [[ "$ws" = "true" ]]; then
        port=`grep -i ssl $NGINX_CONF_PATH${domain}.conf 2>/dev/null | head -n1 | awk '{print $2}'`
    else
        port=`grep port $CONFIG_FILE 2>/dev/null | cut -d: -f2 | tr -d \",' '`
    fi
    res=`grep -i kcp $CONFIG_FILE 2>/dev/null`
    if [[ "$res" != "" ]]; then
        kcp="true"
        type=`grep header -A 3 $CONFIG_FILE 2>/dev/null | grep 'type' | cut -d: -f2 | tr -d \",' '`
        seed=`grep seed $CONFIG_FILE 2>/dev/null | cut -d: -f2 | tr -d \",' '`
    fi

    vmess=`grep vmess $CONFIG_FILE 2>/dev/null`
    if [[ "$vmess" = "" ]]; then
        trojan=`grep trojan $CONFIG_FILE 2>/dev/null`
        if [[ "$trojan" = "" ]]; then
            vless="true"
            protocol="VLESS"
            # 检查是否有TLS配置
            security=`grep security $CONFIG_FILE 2>/dev/null | cut -d: -f2 | tr -d \",' '`
            if [[ "$security" = "tls" || "$security" = "xtls" ]]; then
                tls="true"
            fi
            xtls=`grep xtlsSettings $CONFIG_FILE 2>/dev/null`
            if [[ "$xtls" != "" ]]; then
                xtls="true"
                flow=`grep flow $CONFIG_FILE 2>/dev/null | cut -d: -f2 | tr -d \",' '`
            else
                flow="无"
            fi
        else
            trojan="true"
            password=`grep password $CONFIG_FILE 2>/dev/null | cut -d: -f2 | tr -d \",' '`
            protocol="trojan"
            tls="true"
            encryption="none"
            xtls=`grep xtlsSettings $CONFIG_FILE 2>/dev/null`
            if [[ "$xtls" != "" ]]; then
                xtls="true"
                flow=`grep flow $CONFIG_FILE 2>/dev/null | cut -d: -f2 | tr -d \",' '`
            else
                flow="无"
            fi
        fi
    fi
}


outputVmess() {
    raw="{
  \"v\":\"2\",
  \"ps\":\"${v4l}-${IP}-网路跳越\",
  \"add\":\"$IP\",
  \"port\":\"${port}\",
  \"id\":\"${uid}\",
  \"aid\":\"$alterid\",
  \"net\":\"tcp\",
  \"type\":\"none\",
  \"host\":\"\",
  \"path\":\"\",
  \"tls\":\"\"
}"
    link=`echo -n ${raw} | base64 -w 0`
    link="vmess://${link}"
mkdir -p /root/xray && echo $link > /root/xray/url.txt
    echo -e "   ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
    echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
    echo -e "   ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
    echo -e "   ${BLUE}额外id(alterid)：${PLAIN} ${RED}${alterid}${PLAIN}"
    echo -e "   ${BLUE}加密方式(security)：${PLAIN} ${RED}auto${PLAIN}"
    echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
    echo  
    echo -e "   ${BLUE}vmess链接:${PLAIN} $RED$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)	
}

outputVmessKCP() {
    echo -e "   ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
    echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
    echo -e "   ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
    echo -e "   ${BLUE}额外id(alterid)：${PLAIN} ${RED}${alterid}${PLAIN}"
    echo -e "   ${BLUE}加密方式(security)：${PLAIN} ${RED}auto${PLAIN}"
    echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
    echo -e "   ${BLUE}伪装类型(type)：${PLAIN} ${RED}${type}${PLAIN}"
    echo -e "   ${BLUE}mkcp seed：${PLAIN} ${RED}${seed}${PLAIN}" 
}

outputTrojan() {
	if [[ "$xtls" == "true" ]]; then
		link="trojan://${password}@${domain}:${port}#${v4l}-${IP}-网路跳越-到期时间:${expiration_time}"
mkdir -p /root/xray && echo $link > /root/xray/url.txt		
		qrlink="https://api.qrserver.com/v1/create-qr-code/?data=${link}&size=300${link}"	
		echo -e "   ${BLUE}IP/域名(address): ${PLAIN} ${RED}${domain}${PLAIN}"
		echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
		echo -e "   ${BLUE}密码(password)：${PLAIN}${RED}${password}${PLAIN}"
		echo -e "   ${BLUE}流控(flow)：${PLAIN}$RED$flow${PLAIN}"
		echo -e "   ${BLUE}加密(encryption)：${PLAIN} ${RED}none${PLAIN}"
		echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
		echo -e "   ${BLUE}底层安全传输(tls)：${PLAIN}${RED}XTLS${PLAIN}"		
	echo	
	echo -e "   ${BLUE}Trojan链接: ${PLAIN}$YELLOW$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo		
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)				
	else
		link="trojan://${password}@${domain}:${port}#${v4l}-${IP}-网路跳越-到期时间:${expiration_time}"
		mkdir -p /root/xray && echo $link > /root/xray/url.txt
		qrlink="https://api.qrserver.com/v1/create-qr-code/?data=${link}&size=300${link}"
		echo -e "   ${BLUE}IP/域名(address): ${PLAIN} ${RED}${domain}${PLAIN}"
		echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
		echo -e "   ${BLUE}密码(password)：${PLAIN}${RED}${password}${PLAIN}"
		echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
		echo -e "   ${BLUE}底层安全传输(tls)：${PLAIN}${RED}TLS${PLAIN}"
	echo	
	echo -e "   ${BLUE}Trojan链接: ${PLAIN}$YELLOW$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo		
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)				
	fi
}

outputVmessTLS() {
    raw="{
  \"v\":\"2\",
  \"ps\":\"${v4l}-${IP}-网路跳越\",
  \"add\":\"$IP\",
  \"port\":\"${port}\",
  \"id\":\"${uid}\",
  \"aid\":\"$alterid\",
  \"net\":\"${network}\",
  \"type\":\"none\",
  \"host\":\"${domain}\",
  \"path\":\"\",
  \"tls\":\"tls\"
}"
    link=`echo -n ${raw} | base64 -w 0`
    link="vmess://${link}"
	mkdir -p /root/xray && echo $link > /root/xray/url.txt
    echo -e "   ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
    echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
    echo -e "   ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
    echo -e "   ${BLUE}额外id(alterid)：${PLAIN} ${RED}${alterid}${PLAIN}"
    echo -e "   ${BLUE}加密方式(security)：${PLAIN} ${RED}none${PLAIN}"
    echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}" 
    echo -e "   ${BLUE}伪装域名/主机名(host)/SNI/peer名称：${PLAIN}${RED}${domain}${PLAIN}"
    echo -e "   ${BLUE}底层安全传输(tls)：${PLAIN}${RED}TLS${PLAIN}"
    echo  
    echo -e "   ${BLUE}vmess链接:${PLAIN} $RED$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)		
}

outputVmessWS() {
    raw="{
  \"v\":\"2\",
  \"ps\":\"${v4l}-${IP}-网路跳越\",
  \"add\":\"$IP\",
  \"port\":\"${port}\",
  \"id\":\"${uid}\",
  \"aid\":\"$alterid\",
  \"net\":\"${network}\",
  \"type\":\"none\",
  \"host\":\"${domain}\",
  \"path\":\"${wspath}\",
  \"tls\":\"tls\"
}"
    link=$(echo -n ${raw} | base64 -w 0)
    link="vmess://${link}"
mkdir -p /root/xray && echo $link > /root/xray/url.txt
    echo -e "   ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
    echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
    echo -e "   ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
    echo -e "   ${BLUE}额外id(alterid)：${PLAIN} ${RED}${alterid}${PLAIN}"
    echo -e "   ${BLUE}加密方式(security)：${PLAIN} ${RED}none${PLAIN}"
    echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}" 
    echo -e "   ${BLUE}伪装类型(type)：${PLAIN}${RED}none${PLAIN}"
    echo -e "   ${BLUE}伪装域名/主机名(host)/SNI/peer名称：${PLAIN}${RED}${domain}${PLAIN}"
    echo -e "   ${BLUE}路径(path)：${PLAIN}${RED}${wspath}${PLAIN}"
    echo -e "   ${BLUE}底层安全传输(tls)：${PLAIN}${RED}TLS${PLAIN}"
    echo  
    echo -e "   ${BLUE}vmess链接:${PLAIN} $RED$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)
}
outputVlessTCP() {
    echo -e "   ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
    echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
    echo -e "   ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
    echo -e "   ${BLUE}加密(encryption)：${PLAIN} ${RED}none${PLAIN}"
    echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
        link="vless://${uid}@${IP}:${port}?encryption=none&security=none&type=tcp#${v4l}-${IP}-网路跳越"
    mkdir -p /root/xray && echo $link > /root/xray/url.txt
    qrlink="https://api.qrserver.com/v1/create-qr-code/?data=vless://${uid}@${IP}:${port}?encryption=none&security=none&type=tcp#${v4l}-${IP}-网路跳越&size=300x300"    
    echo	
    echo -e "   ${BLUE}vless链接: ${PLAIN}$YELLOW$(cat /root/xray/url.txt)$PLAIN"
    echo
    echo -e "   ${BLUE}二维码链接: ${PLAIN}$GREEN$qrlink$PLAIN"    
    echo
    echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}"
    echo
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)
}

showInfo() {
    # 检查是否是 SOCKS5 配置
    socks=$(grep -i '"protocol": "socks"' $CONFIG_FILE)
    if [[ -n "$socks" ]]; then
        PORT=$(jq -r '.inbounds[0].port' $CONFIG_FILE)
        user=$(jq -r '.inbounds[0].settings.accounts[0].user' $CONFIG_FILE)
        password=$(jq -r '.inbounds[0].settings.accounts[0].pass' $CONFIG_FILE)

        auth="${user}:${password}@${IP}:${PORT}"
        comment="${v4l}-${IP}-网路跳越"
        mkdir -p /root/socks5
        echo "socks://${auth}#${comment}" > /root/socks5/url.txt
        link="socks://$(echo -n "$auth" | base64 -w 0)#$(echo -n "$comment" | base64 -w 0)"
        qrlink="https://api.qrserver.com/v1/create-qr-code/?data=${link}&size=300x300"       
        echo -e "\n   ${BLUE}地址: ${PLAIN}${RED}${IP}${PLAIN}"
        echo -e "   ${BLUE}端口: ${PLAIN}${RED}${PORT}${PLAIN}"
        echo -e "   ${BLUE}用户: ${PLAIN}${RED}${user}${PLAIN}"
        echo -e "   ${BLUE}密码: ${PLAIN}${RED}${password}${PLAIN}"
        echo  
        echo -e "   ${BLUE}Socks5 链接:${PLAIN} $RED${link}$PLAIN"
        echo
        echo -e "   ${BLUE}二维码链接:${PLAIN} $GREEN$qrlink$PLAIN" 
        echo -e "              浏览器打开二维码链接    "
        echo
        echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"    
        qrencode -t ANSIUTF8 -s 1 "socks://${auth}#${comment}"
        qrencode -o ~/xray-${IP}-网路跳越.png -s 6 "socks://${auth}#${comment}"
        return 0
    fi
    
    # 检查是否是 Reality 配置
    reality=$(grep -i '"security": "reality"' $CONFIG_FILE)
    if [[ -n "$reality" ]]; then
        outputReality
        return 0
    fi            
    
    res=`status`
    if [[ $res -lt 2 ]]; then
        colorEcho $RED " Xray未安装，请先安装！"
        return
    fi
    
    echo ""
    echo -n -e " ${BLUE}Xray运行状态：${PLAIN}"
    statusText
    echo -e " ${BLUE}Xray配置文件: ${PLAIN} ${RED}${CONFIG_FILE}${PLAIN}"
    colorEcho $BLUE " Xray配置信息：${v4l}-${IP}-网路跳越"

    getConfigFileInfo

    if [[ -z "$uid" ]]; then
        colorEcho $RED " 无法读取配置文件或配置无效"
        return
    fi

    echo -e "   ${BLUE}协议: ${PLAIN} ${RED}${protocol}${PLAIN}"
    if [[ "$trojan" = "true" ]]; then
        outputTrojan
        return 0
    fi
    if [[ "$vless" = "false" ]]; then
        if [[ "$kcp" = "true" ]]; then
            outputVmessKCP
            return 0
        fi
        if [[ "$tls" = "false" ]]; then
            outputVmess
        elif [[ "$ws" = "false" ]]; then
            outputVmessTLS
        else
            outputVmessWS
        fi
    else
        if [[ "$kcp" = "true" ]]; then
            echo -e "   ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
            echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
            echo -e "   ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
            echo -e "   ${BLUE}加密(encryption)：${PLAIN} ${RED}none${PLAIN}"
            echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
            echo -e "   ${BLUE}伪装类型(type)：${PLAIN} ${RED}${type}${PLAIN}"
            echo -e "   ${BLUE}mkcp seed：${PLAIN} ${RED}${seed}${PLAIN}" 
            return 0
        fi
        
        # VLESS+TCP（无TLS）输出
        if [[ "$tls" = "false" && "$ws" = "false" ]]; then
            outputVlessTCP
            return 0
        fi
        
        if [[ "$xtls" = "true" ]]; then
            echo -e " ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
            echo -e " ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
            echo -e " ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
            echo -e " ${BLUE}流控(flow)：${PLAIN}$RED$flow${PLAIN}"
            echo -e " ${BLUE}加密(encryption)：${PLAIN} ${RED}none${PLAIN}"
            echo -e " ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}" 
            echo -e " ${BLUE}伪装类型(type)：${PLAIN}${RED}none$PLAIN"
            echo -e " ${BLUE}伪装域名/主机名(host)/SNI/peer名称：${PLAIN}${RED}${domain}${PLAIN}"
            echo -e " ${BLUE}底层安全传输(tls)：${PLAIN}${RED}XTLS${PLAIN}"
            			# 通用格式(VLESS+TCP+xTLS)
			link="vless://${uid}@${domain}:${port}?encryption=none&security=xtls&type=tcp&host=${domain}&headerType=none#${v4l}-${IP}-网路跳越-到期时间:${expiration_time}"
            mkdir -p /root/xray && echo $link > /root/xray/url.txt			
			qrlink="https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless%3A%2F%2F${uid}%40${domain}%3A${port}%3Fencryption%3Dnone%26security%3Dtls%26type%3Dtcp%26host%3D${domain}%26sni%3D${domain}%26path%3D${wspath}%23${Country}-${IP}-网路跳越"
				echo	
	echo -e "   ${BLUE}vless链接: ${PLAIN}$YELLOW$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码链接: ${PLAIN}$GREEN$qrlink$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo		
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)	

        elif [[ "$ws" = "false" ]]; then
            echo -e " ${BLUE}IP(address):  ${PLAIN}${RED}${IP}${PLAIN}"
            echo -e " ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
            echo -e " ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
            echo -e " ${BLUE}流控(flow)：${PLAIN}$RED$flow${PLAIN}"
            echo -e " ${BLUE}加密(encryption)：${PLAIN} ${RED}none${PLAIN}"
            echo -e " ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}" 
            echo -e " ${BLUE}伪装类型(type)：${PLAIN}${RED}none$PLAIN"
            echo -e " ${BLUE}伪装域名/主机名(host)/SNI/peer名称：${PLAIN}${RED}${domain}${PLAIN}"
            echo -e " ${BLUE}底层安全传输(tls)：${PLAIN}${RED}TLS${PLAIN}"
            			# 通用格式(VLESS+TCP+TLS)
			link="vless://${uid}@${domain}:${port}?encryption=none&security=tls&type=tcp&host=${domain}&headerType=none#${v4l}-${IP}-网路跳越"
			            mkdir -p /root/xray && echo $link > /root/xray/url.txt	
			qrlink="https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless%3A%2F%2F${uid}%40${domain}%3A${port}%3Fencryption%3Dnone%26security%3Dtls%26type%3Dtcp%26host%3D${domain}%26sni%3D${domain}%26path%3D${wspath}%23${Country}-${IP}-网路跳越"
	echo	
	echo -e "   ${BLUE}vless链接: ${PLAIN}$YELLOW$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码链接: ${PLAIN}$GREEN$qrlink$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo	
	    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)
        else
            echo -e " ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
            echo -e " ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
            echo -e " ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
            echo -e " ${BLUE}流控(flow)：${PLAIN}$RED$flow${PLAIN}"
            echo -e " ${BLUE}加密(encryption)：${PLAIN} ${RED}none${PLAIN}"
            echo -e " ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}" 
            echo -e " ${BLUE}伪装类型(type)：${PLAIN}${RED}none$PLAIN"
            echo -e " ${BLUE}伪装域名/主机名(host)/SNI/peer名称：${PLAIN}${RED}${domain}${PLAIN}"
            echo -e " ${BLUE}路径(path)：${PLAIN}${RED}${wspath}${PLAIN}"
            echo -e " ${BLUE}底层安全传输(tls)：${PLAIN}${RED}TLS${PLAIN}"
            			# 通用格式(VLESS+WS+TLS) 
			link="vless://${uid}@${domain}:${port}?encryption=none&security=tls&type=ws&host=${domain}&sni=${domain}&path=${wspath}#${v4l}-${IP}-网路跳越"
			            mkdir -p /root/xray && echo $link > /root/xray/url.txt	
			qrlink="https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless%3A%2F%2F${uid}%40${domain}%3A${port}%3Fencryption%3Dnone%26security%3Dtls%26type%3Dws%26host%3D${domain}%26sni%3D${domain}%26path%3D${wspath}%23${Country}-${IP}-网路跳越"
	echo	
	echo -e "   ${BLUE}vless链接: ${PLAIN}$YELLOW$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码链接: ${PLAIN}$GREEN$qrlink$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo		
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)
        fi
    fi
}

outputReality() {
    # 从配置文件中提取信息
    local uuid=$(grep '"id":' $CONFIG_FILE | head -1 | cut -d'"' -f4)
    local port=$(grep '"port":' $CONFIG_FILE | head -1 | awk '{print $2}' | tr -d ',')
    echo ""
    colorEcho $BLUE " Xray Reality 配置信息："
    echo -e "   ${BLUE}协议: ${PLAIN} ${RED}VLESS+Vision+Reality${PLAIN}"
    echo -e "   ${BLUE}地址(address): ${PLAIN} ${RED}${IP}${PLAIN}"
    echo -e "   ${BLUE}端口(port): ${PLAIN} ${RED}${port}${PLAIN}"
    echo -e "   ${BLUE}ID(uuid): ${PLAIN} ${RED}${uuid}${PLAIN}"
    echo -e "   ${BLUE}流控(flow): ${PLAIN} ${RED}xtls-rprx-vision${PLAIN}"
    echo -e "   ${BLUE}公钥(Public Key): ${PLAIN} ${RED}${public_key}${PLAIN}"
    echo -e "   ${BLUE}Short ID: ${PLAIN} ${RED}${SELECTED_SHORT_ID}${PLAIN}"
    echo -e "   ${BLUE}伪装目标(Dest): ${PLAIN} ${RED}${REALITY_SERVER_NAME}${PLAIN}"
    echo -e "   ${BLUE}指纹(Fingerprint): ${PLAIN} ${RED}chrome${PLAIN}"
    # 生成分享链接
    local link="vless://${uuid}@${IP}:${port}?flow=xtls-rprx-vision&encryption=none&type=tcp&security=reality&sni=${REALITY_SERVER_NAME}&fp=chrome&pbk=${public_key}&sid=${SELECTED_SHORT_ID}#${v4l}-${IP}-网路跳越-Reality"   
          qrlink="https://api.qrserver.com/v1/create-qr-code/?data=vless://${uuid}@${IP}:${port}?flow=xtls-rprx-vision&encryption=none&type=tcp&security=reality&sni=${REALITY_SERVER_NAME}&fp=chrome&pbk=${public_key}&sid=${SELECTED_SHORT_ID}#${v4l}-${IP}-网路跳越-Reality"
    mkdir -p /root/xray
    echo "$link" > /root/xray/url.txt
    echo ""
    echo -e "   ${BLUE}Reality链接: ${RED}$link${PLAIN}"
	echo
	echo -e "   ${BLUE}二维码链接: ${PLAIN}$GREEN$qrlink$PLAIN"
	echo
    echo -e "   ${BLUE}二维码位置: ${PLAIN}/root/xray-${IP}-网路跳越.png"
    echo ""
    # 生成二维码
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)

}

showLog() {
	res=$(status)
	[[ $res -lt 2 ]] && red "Xray未安装，请先安装！" && exit 1
	journalctl -xen -u xray --no-pager
}


open_ports() {
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	setenforce 0
	ufw disable
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -t nat -F
	iptables -t mangle -F
	iptables -F
	iptables -X
	netfilter-persistent save
	yellow "VPS中的所有网络端口已开启"
}

#禁用IPv6
closeipv6() {
	clear
	sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
	sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
	sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
	sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
	sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
	sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

	echo "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" >>/etc/sysctl.d/99-sysctl.conf
	sysctl --system
	green "禁用IPv6结束，可能需要重启！"
}

#开启IPv6
openipv6() {
	clear
	sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
	sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
	sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
	sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
	sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
	sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

	echo "net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0" >>/etc/sysctl.d/99-sysctl.conf
	sysctl --system
	green "开启IPv6结束，可能需要重启！"
}

menu() {
    clear
    echo "#———————————————————————————————————————————————————————————#"	
    echo -e "#               ${RED}Xray一键安装脚本${PLAIN}                      #"
    echo -e "# ${GREEN}作者${PLAIN}: 网络跳越(sldm)                                      #"	
    echo -e "${GREEN}系统${PLAIN}：${BLUE}${OS}${PLAIN}"
    echo -e "${GREEN}虚拟化${PLAIN}:${BLUE}${virtual}${PLAIN}"
    echo -e "${GREEN}内核${PLAIN}：${BLUE}${kern}${PLAIN}"
    echo "#———————————————————————————————————————————————————————————#"	
    echo   " ———————————————————VMESS协议———————————————"
    echo -e "  ${GREEN}1.${PLAIN}    安装Xray-VMESS+TCP"
    echo -e "  ${GREEN}2.${PLAIN}    安装Xray-${BLUE}VMESS+mKCP${PLAIN}"
    echo -e "  ${GREEN}3.${PLAIN}    安装Xray-VMESS+TCP+TLS"
    echo -e "  ${GREEN}4.${PLAIN}    安装Xray-${BLUE}VMESS+WS+TLS${PLAIN}${RED}(推荐)${PLAIN}"
    echo   " ———————————————————VLESS协议———————————————"
    echo -e "  ${GREEN}5.${PLAIN}    安装Xray-${BLUE}VLESS+TCP"    
    echo -e "  ${GREEN}6.${PLAIN}    安装Xray-${BLUE}VLESS+mKCP${PLAIN}"   
    echo -e "  ${GREEN}7.${PLAIN}    安装Xray-VLESS+TCP+TLS"
    echo -e "  ${GREEN}8.${PLAIN}    安装Xray-${BLUE}VLESS+WS+TLS${PLAIN}${RED}(可过cdn)${PLAIN}"
    echo -e "  ${GREEN}9.${PLAIN}    安装Xray-${BLUE}VLESS+TCP+XTLS${PLAIN}"
    echo   " ————————————————————trojan协议———————————————"
    echo -e "  ${GREEN}10.${PLAIN}   安装${BLUE}trojan${PLAIN}${RED}(推荐)${PLAIN}"
    echo -e "  ${GREEN}11.${PLAIN}   安装${BLUE}trojan+XTLS${PLAIN}${RED}(推荐)${PLAIN}"
    echo   " ————————————————————Socks5协议———————————————"
    echo -e "  ${GREEN}12.${PLAIN}   安装Xray-${BLUE}Socks5${PLAIN}${RED}(明文传输)${PLAIN}"
    echo   " ————————————————————Reality协议———————————————"
    echo -e "  ${GREEN}13.${PLAIN}   安装Xray-${BLUE}VLESS+Vision-uTLS+Reality${PLAIN}${RED}(推荐)${PLAIN}"
    echo " -------------"
    echo -e "  ${GREEN}14.${PLAIN}   更新Xray"
    echo -e "  ${GREEN}15.${RED}     卸载Xray${PLAIN}"
    echo " -------------"
    echo -e "  ${GREEN}16.${PLAIN}   启动Xray"
    echo -e "  ${GREEN}17.${PLAIN}   重启Xray"
    echo -e "  ${GREEN}18.${PLAIN}   停止Xray"
    echo " ------------"
    echo -e "  ${GREEN}19.${PLAIN}   查看Xray配置"
    echo -e "  ${GREEN}20.${PLAIN}   查看Xray日志"
    echo " ——————————————"
    echo -e "  ${GREEN}21.${PLAIN}   启动nginx"
    echo -e "  ${GREEN}22.${PLAIN}   重启nginx"
    echo -e "  ${GREEN}23.${PLAIN}   检查 nginx 状态"    
    echo " ——————————————"
	echo -e "  ${GREEN}24.${PLAIN}  放开VPS的所有端口"
	echo -e "  ${GREEN}25.${PLAIN}  开启IPv6"
	echo -e "  ${GREEN}26.${PLAIN}  禁用IPv6"
	echo " -------------"
    echo -e "  ${GREEN}0.${PLAIN}    退出"
    echo -n "    当前状态："
    statusText
    echo 
    read -t 30 -p " 请选择操作[0-20]（30秒内没有输入则自动选择1）：" answer
    if [[ -z "$answer" ]]; then
        answer=1
        echo -e "\n未输入选择，自动选择 ${answer}."
    fi
    case $answer in
	0) exit 1 ;;
	1) install ;;
	2) KCP="true" && install ;;
	3) TLS="true" && install ;;
	4) TLS="true" && WS="true" && install ;;
    5)  VLESS="true"&& install ;;	
	6) VLESS="true" && KCP="true" && install ;;
	7) VLESS="true" && TLS="true" && install ;;
	8) VLESS="true" && TLS="true" && WS="true" && install ;;
	9) VLESS="true" && TLS="true" && XTLS="true" && install ;;
	10) TROJAN="true" && TLS="true" && install ;;
	11) TROJAN="true" && TLS="true" && XTLS="true" && install ;;
    12) SOCKS5="true" && install ;; 
    13) VLESS="true" && REALITY="true" && install ;;
    14) update ;;
    15) uninstall ;;
    16) start ;;
    17) restart ;;
    18) stop  ;;
    19) showInfo ;;
    20) showLog ;;
    21) nginx ;;
    22) nginx2 ;; 
    23) nginx3 ;; 	
	24) open_ports ;;
	25) openipv6 ;;
	26) closeipv6 ;;        
     *) colorEcho $RED " 请选择正确的操作！" && exit 1 ;;
    esac
}

checkSystem

action=$1
[[ -z $1 ]] && action=menu
case "$action" in
    menu|update|uninstall|start|restart|stop|showInfo|showLog)
        ${action}
        ;;
    *)
        echo " 参数错误"
        echo " 用法: `basename $0` [menu|update|uninstall|start|restart|stop|showInfo|showLog]"
        ;;
esac

}

v2rayy() {
#!/bin/bash
# by 网络跳越(hijk) 

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

# 设置全局快捷键
cp -f "$0" /usr/local/bin/v
chmod +x /usr/local/bin/v
# 设置全局快捷键
cp -f "$0" /usr/local/bin/V
chmod +x /usr/local/bin/V

# 以下网站是随机从Google上找到的无广告小说网站，不喜欢请改成其他网址，以http或https开头
# 搭建好后无法打开伪装域名，可能是反代小说网站挂了，请在网站留言，或者Github发issue，以便替换新的网站
SITES=(
	https://www.jjwxc.net/
	https://culture.ifeng.com/
	http://www.bhzwy.com/
	http://book.ce.cn/
	https://wap.faloo.com/
	https://www.09k.net/
	https://jsxs6.shop/
	https://www.kehu33.asia/
	http://www.bookshuku.info/
	http://www.qishuxx.com/
	https://www.txt80.cc/
	https://www.bqg789.com/
	https://www.txt99.org
	http://b.faloo.com/
	https://www.bookben.net/
	http://www.fbook.net/
	https://shuqi.com/
	https://www.jjwxc.net/
	https://www.shukeba.com/
	https://www.xiaxs.la/
	https://www.shubl.com/
	https://book.sfacg.com/
	http://www.wzzww.com/
	http://www.zongheng.com/
	https://www.heiyan.com/ ​
	https://chuangshi.qq.com/
	http://www.wjsw.com/
	http://www.shuhai.com/
	https://www.facerome.com/
	http://www.bayueju.com/
	https://www.17k.com/
     http://xs.56dyc.com/
	https://www.23xsww.net/
)

CONFIG_FILE="/etc/v2ray/config.json"
SERVICE_FILE="/etc/systemd/system/v2ray.service"
OS=$(hostnamectl | grep -i system | cut -d: -f2)
virtual=$(systemd-detect-virt)
 kern=$(uname -r)
#  识别国家
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
v4=$(curl -s4m10 ip.sb -k)
v4l=`curl -sm10 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"'`

# 检查服务器网络环境
    pv6=$(curl -s6m8 api64.ipify.org -k)
    pv4=$(curl -s4m8 api64.ipify.org -k)
IP=$(curl -s4m8 ip.sb)
[[ "$?" != "0" ]] && IP=$(curl -s6m8 ip.sb )
#=====================
BT="false"
NGINX_CONF_PATH="/etc/nginx/conf.d/"
res=`which bt 2>/dev/null`

if [[ "$res" != "" ]]; then
    BT="true"
    NGINX_CONF_PATH="/www/server/panel/vhost/nginx/"
fi

VLESS="false"
TROJAN="false"
TLS="false"
WS="false"
XTLS="false"
KCP="false"

checkSystem() {
    result=$(id | awk '{print $1}')
    if [[ $result != "uid=0(root)" ]]; then
        colorEcho $RED " 请以root身份执行该脚本"
        exit 1
    fi

    res=`which yum 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        res=`which apt 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " 不受支持的Linux系统"
            exit 1
        fi
        PMT="apt"
        CMD_INSTALL="apt install -y "
        CMD_REMOVE="apt remove -y "
        CMD_UPGRADE="apt update; apt upgrade -y; apt autoremove -y"
    else
        PMT="yum"
        CMD_INSTALL="yum install -y "
        CMD_REMOVE="yum remove -y "
        CMD_UPGRADE="yum update -y"
    fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " 系统版本过低，请升级到最新版本"
        exit 1
    fi
}

colorEcho() {
    echo -e "${1}${@:2}${PLAIN}"
}

configNeedNginx() {
    local ws=`grep wsSettings $CONFIG_FILE`
    if [[ -z "$ws" ]]; then
        echo no
        return
    fi
    echo yes
}

needNginx() {
    if [[ "$WS" = "false" ]]; then
        echo no
        return
    fi
    echo yes
}

status() {
    if [[ ! -f /usr/bin/v2ray/v2ray ]]; then
        echo 0
        return
    fi
    if [[ ! -f $CONFIG_FILE ]]; then
        echo 1
        return
    fi
    port=`grep port $CONFIG_FILE| head -n 1| cut -d: -f2| tr -d \",' '`
    res=`ss -nutlp| grep ${port} | grep -i v2ray`
    if [[ -z "$res" ]]; then
        echo 2
        return
    fi

    if [[ `configNeedNginx` != "yes" ]]; then
        echo 3
    else
        res=`ss -nutlp|grep -i nginx`
        if [[ -z "$res" ]]; then
            echo 4
        else
            echo 5
        fi
    fi
}

statusText() {
    res=`status`
    case $res in
        2)
            echo -e ${GREEN}已安装${PLAIN} ${RED}未运行${PLAIN}
            ;;
        3)
            echo -e ${GREEN}已安装${PLAIN} ${GREEN}V2ray正在运行${PLAIN}
            ;;
        4)
            echo -e ${GREEN}已安装${PLAIN} ${GREEN}V2ray正在运行${PLAIN}, ${RED}Nginx未运行${PLAIN}
            ;;
        5)
            echo -e ${GREEN}已安装${PLAIN} ${GREEN}V2ray正在运行, Nginx正在运行${PLAIN}
            ;;
        *)
            echo -e ${RED}未安装${PLAIN}
            ;;
    esac
}

normalizeVersion() {
    if [ -n "$1" ]; then
        case "$1" in
            v*)
                echo "v5.41.0"
            ;;
            *)
                echo "$1"
            ;;
        esac
    else
        echo ""
    fi
}

# 1: new V2Ray. 0: no. 1: yes. 2: not installed. 3: check failed.
getVersion() {
    if /usr/bin/v2ray/v2ray -version >/dev/null 2>&1;then
	VER="$(/usr/bin/v2ray/v2ray -version | awk 'NR==1 {print $2}')"
    else
	VER="$(/usr/bin/v2ray/v2ray version | awk 'NR==1 {print $2}')"
    fi
    RETVAL=$?
    CUR_VER="$(normalizeVersion "$(echo "$VER" | head -n 1 | cut -d " " -f2)")"
    TAG_URL="https://api.github.com/repos/v2fly/v2ray-core/releases/latest"
    NEW_VER="$(normalizeVersion "$(curl -s "${TAG_URL}" --connect-timeout 10| tr ',' '\n' | grep 'tag_name' | cut -d\" -f4)")"
    # 解决通过Github API获取v2ray最新版本失败问题
    if [[ $NEW_VER == "" ]]; then
        NEW_VER=$1
    fi	
    if [[ "$XTLS" = "true" ]]; then
        NEW_VER=v4.32.1
    fi

    if [[ $? -ne 0 ]] || [[ $NEW_VER == "" ]]; then
        colorEcho $RED " 检查V2ray版本信息失败，请检查网络"
        return 3
    elif [[ $RETVAL -ne 0 ]];then
        return 2
    elif [[ $NEW_VER != $CUR_VER ]];then
        return 1
    fi
    return 0
}

archAffix(){
    case "$(uname -m)" in
        i686|i386)
            echo '32'
        ;;
        x86_64|amd64)
            echo '64'
        ;;
        *armv7*)
            echo 'arm32-v7a'
            ;;
        armv6*)
            echo 'arm32-v6a'
        ;;
        *armv8*|aarch64)
            echo 'arm64-v8a'
        ;;
        *mips64le*)
            echo 'mips64le'
        ;;
        *mips64*)
            echo 'mips64'
        ;;
        *mipsle*)
            echo 'mipsle'
        ;;
        *mips*)
            echo 'mips'
        ;;
        *s390x*)
            echo 's390x'
        ;;
        ppc64le)
            echo 'ppc64le'
        ;;
        ppc64)
            echo 'ppc64'
        ;;
        *)
            colorEcho $RED " 不支持的CPU架构！"
            exit 1
        ;;
    esac

	return 0
}

getData() {
    if [[ "$TLS" = "true" || "$XTLS" = "true" ]]; then
        echo ""
        echo " V2ray一键脚本，运行之前请确认如下条件已经具备："
        colorEcho ${YELLOW} "  1. 一个伪装域名"
        colorEcho ${YELLOW} "  2. 伪装域名DNS解析指向当前服务器ip（${IP}）"
        colorEcho ${BLUE} "  3. 如果/root目录下有 v2ray.pem 和 v2ray.key 证书密钥文件，无需理会条件2"
        echo " "
            read -p " 请输入伪装域名：" DOMAIN
            if [[ -z "${DOMAIN}" ]]; then
                colorEcho ${RED} " 域名输入错误，请重新输入！"
            fi
        DOMAIN=${DOMAIN,,}
        colorEcho ${BLUE}  " 伪装域名(host)：$DOMAIN"
        if [[ -f ~/v2ray.pem && -f ~/v2ray.key ]]; then
            colorEcho ${BLUE}  " 检测到自有证书，将使用其部署"
            CERT_FILE="/etc/v2ray/${DOMAIN}.pem"
            KEY_FILE="/etc/v2ray/${DOMAIN}.key"
        else
	    resolve=$(curl -sH "accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=${DOMAIN}&type=A" && \
          	      curl -sH "accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=${DOMAIN}&type=AAAA")
	    if ! echo "$resolve" | grep -q -e "$pv4" -e "$pv6"; then
		if echo $resolve | grep -q html; then
			colorEcho ${BLUE}  " 域名解析失败，请添加域名解析记录或等待DNS同步，稍后再试。"
		else
			colorEcho ${BLUE}  " ${DOMAIN} 解析结果：${pv4}${pv6}"
		fi
                colorEcho ${RED}  " 域名未解析到当前服务器IP("${BLUE}"ipv4:"${RED}"${pv4} / "${BLUE}"ipv6:"${RED}"${pv6} )!"
                exit 1
            fi
        fi
    fi

    echo ""
    if [[ "$(needNginx)" = "no" ]]; then
        if [[ "$TLS" = "true" ]]; then
            read -p " 请输入v2ray监听端口[默认随机]：" PORT
			[[ -z "${PORT}" ]] && PORT=$(shuf -i1000-65535 -n1)
        else
            read -p " 请输入v2ray监听端口[100-65535的一个数字]：" PORT
            [[ -z "${PORT}" ]] && PORT=`shuf -i10000-65000 -n1`
            if [[ "${PORT:0:1}" = "0" ]]; then
                colorEcho ${RED}  " 端口不能以0开头"
                exit 1
            fi
        fi
        colorEcho ${BLUE}  " v2ray端口：$PORT"
    else
        read -p " 请输入Nginx监听端口[10000-65535的一个数字，默认随机]：" PORT
        [[ -z "${PORT}" ]] && PORT=$(shuf -i2000-65535 -n1)
        if [ "${PORT:0:1}" = "0" ]; then
            colorEcho ${BLUE}  " 端口不能以0开头"
            exit 1
        fi
        colorEcho ${BLUE}  " Nginx端口：$PORT"
        V2PORT=`shuf -i2000-65000 -n1`
    fi

    if [[ "$KCP" = "true" ]]; then
        echo ""
        colorEcho $BLUE " 请选择伪装类型："
        echo "   1) 无"
        echo "   2) BT下载"
        echo "   3) 视频通话"
        echo "   4) 微信视频通话"
        echo "   5) dtls"
        echo "   6) wiregard"
        read -p "  请选择伪装类型[默认：无]：" answer
        case $answer in
            2)
                HEADER_TYPE="utp"
                ;;
            3)
                HEADER_TYPE="srtp"
                ;;
            4)
                HEADER_TYPE="wechat-video"
                ;;
            5)
                HEADER_TYPE="dtls"
                ;;
            6)
                HEADER_TYPE="wireguard"
                ;;
            *)
                HEADER_TYPE="none"
                ;;
        esac
        colorEcho $BLUE " 伪装类型：$HEADER_TYPE"
        SEED=`cat /proc/sys/kernel/random/uuid`
    fi

    if [[ "$TROJAN" = "true" ]]; then
        echo ""
        read -p " 请设置trojan密码（不输则随机生成）:" PASSWORD
        [[ -z "$PASSWORD" ]] && PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
        colorEcho $BLUE " trojan密码：$PASSWORD"
    fi

    if [[ "$XTLS" = "true" ]]; then
        echo ""
        colorEcho $BLUE " 请选择流控模式:" 
        echo -e "   1) xtls-rprx-direct [$RED推荐$PLAIN]"
        echo "   2) xtls-rprx-origin"
        read -p "  请选择流控模式[默认:direct]" answer
        [[ -z "$answer" ]] && answer=1
        case $answer in
            1)
                FLOW="xtls-rprx-direct"
                ;;
            2)
                FLOW="xtls-rprx-origin"
                ;;
            *)
                colorEcho $RED " 无效选项，使用默认的xtls-rprx-direct"
                FLOW="xtls-rprx-direct"
                ;;
        esac
        colorEcho $BLUE " 流控模式：$FLOW"
    fi

    if [[ "${WS}" = "true" ]]; then
        echo ""
        while true
        do
            read -p " 请输入伪装路径，以/开头(不懂请直接回车)：" WSPATH
            if [[ -z "${WSPATH}" ]]; then
                len=`shuf -i8-16 -n1`
                ws=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $len | head -n 1`
                WSPATH="/$ws"
                break
            elif [[ "${WSPATH:0:1}" != "/" ]]; then
                colorEcho ${RED}  " 伪装路径必须以/开头！"
            elif [[ "${WSPATH}" = "/" ]]; then
                colorEcho ${RED}   " 不能使用根路径！"
            else
                break
            fi
        done
        colorEcho ${BLUE}  " ws路径：$WSPATH"
    fi

    if [[ "$TLS" = "true" || "$XTLS" = "true" ]]; then
		echo ""
		colorEcho $BLUE " 请选择伪装站类型:"
		echo		
		echo "   1) 静态网站：小白不建议使用这个(位于/usr/share/nginx/html)"
		echo "   2) 34个小说站(随机)"
          echo "   3) 美女站1(https://www.jp94.com)"
          echo "   4) 美女站2(https://www.1jiepai.com)"				
          echo "   5) 世嘉maimai站(https://maimai.sega.jp)"
		echo "   6) 高清壁纸站1(https://bing.ioliu.cn)"
		echo "   7) 高清壁纸站2(https://wallhaven.cc)"
		echo "   8) 自定义反代站点(需以http或者https开头)"
		echo		
		read -p " 请选择伪装网站类型[默认:34个小说站(随机选择一个)]" answer
		if [[ -z "$answer" ]]; then
                len=${#SITES[@]}
                ((len--))
                index=$(shuf -i 0-$len -n 1)
                PROXY_URL=${SITES[$index]}			
		else
			case $answer in
				1) PROXY_URL="" 
				;;
				2)
					len=${#SITES[@]}
					((len--))
					while true; do
						index=$(shuf -i0-${len} -n1)
						PROXY_URL=${SITES[$index]}
						host=$(echo ${PROXY_URL} | cut -d/ -f3)
						ip=$(curl -sm8 https://ip.sb/?ip=${host})
						res=$(echo -n ${ip} | grep ${host})
						if [[ "${res}" == "" ]]; then
							echo "$ip $host" >>/etc/hosts
							break
						fi
					done
					;;
				3) PROXY_URL="https://www.jp94.com" ;;
				4) PROXY_URL="https://www.1jiepai.com" ;;
                5) PROXY_URL="https://maimai.sega.jp" ;;
				6) PROXY_URL="https://bing.ioliu.cn" ;;
				7) PROXY_URL="https://wallhaven.cc" ;;				
				8)
					read -p " 请输入反代站点(以http或者https开头)：" PROXY_URL
					if [[ -z "$PROXY_URL" ]]; then
						colorEcho $RED " 请输入反代网站！"
						exit 1
					elif [[ "${PROXY_URL:0:4}" != "http" ]]; then
						colorEcho $RED " 反代网站必须以http或https开头！"
						exit 1
					fi
					;;
            *)
                colorEcho $RED " 请输入正确的选项！"
                exit 1
            esac
        fi
        REMOTE_HOST=`echo ${PROXY_URL} | cut -d/ -f3`
        colorEcho $BLUE " 伪装网站：$PROXY_URL"

        echo ""
ALLOW_SPIDER="n"
        fi
}

installNginx() {
    echo ""
    colorEcho $BLUE " 安装nginx..."
    if [[ "$BT" = "false" ]]; then
        if [[ "$PMT" = "yum" ]]; then
            $CMD_INSTALL epel-release
            if [[ "$?" != "0" ]]; then
                echo '[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true' > /etc/yum.repos.d/nginx.repo
            fi
        fi
        $CMD_INSTALL nginx
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " Nginx安装失败，请联系作者"
            exit 1
        fi
        systemctl enable nginx
    else
        res=`which nginx 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " 您安装了宝塔，请在宝塔后台安装nginx后再运行本脚本"
            exit 1
        fi
    fi
}

startNginx() {
    if [[ "$BT" = "false" ]]; then
        systemctl start nginx
    else
        nginx -c /www/server/nginx/conf/nginx.conf
    fi
}

stopNginx() {
    if [[ "$BT" = "false" ]]; then
        systemctl stop nginx
    else
        res=`ps aux | grep -i nginx`
        if [[ "$res" != "" ]]; then
            nginx -s stop
        fi
    fi
}

getCert() {
    mkdir -p /etc/v2ray
    if [[ -z ${CERT_FILE+x} ]]; then
        stopNginx
        sleep 2
        res=$(netstat -ntlp | grep -E ':80 |:443 ')
        if [[ "${res}" != "" ]]; then
            colorEcho ${RED} "其他进程占用了80或443端口，5秒后自动尝试释放"
            echo "端口占用信息如下："
            echo "${res}"
            sleep 5
            # 获取占用端口的进程ID
            pids=$(netstat -ntlp | grep -E ':80 |:443 ' | awk '{print $7}' | cut -d'/' -f1)
            # 强制终止占用端口的进程
            for pid in $pids; do
                kill -9 $pid
                echo "终止进程，PID: $pid"
            done
            sleep 3
            res=$(netstat -ntlp | grep -E ':80 |:443 ')
            if [[ "${res}" != "" ]]; then
                colorEcho ${RED} "端口仍被占用，请手动关闭占用端口的进程后再运行一键脚本"
                echo "端口占用信息如下："
                echo "${res}"
                exit 1
            fi
        fi
        $CMD_INSTALL socat openssl
        if [[ "$PMT" = "yum" ]]; then
            $CMD_INSTALL cronie
            systemctl start crond
            systemctl enable crond
        else
            $CMD_INSTALL cron
            systemctl start cron
            systemctl enable cron
        fi
        curl -sL https://get.acme.sh | sh -s email=1150315739@qq.com
        source ~/.bashrc
        ~/.acme.sh/acme.sh  --upgrade  --auto-upgrade
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

		if [[ "$ipv6Status" = "on" ]]; then
			if [[ "$BT" = "false" ]]; then
				~/.acme.sh/acme.sh   --issue -d $DOMAIN --keylength ec-256 --pre-hook "systemctl stop nginx" --post-hook "systemctl restart nginx"  --standalone --listen-v6 --insecure
			else
				~/.acme.sh/acme.sh   --issue -d $DOMAIN --keylength ec-256 --pre-hook "nginx -s stop || { echo -n ''; }" --post-hook "nginx -c /www/server/nginx/conf/nginx.conf || { echo -n ''; }"  --standalone --listen-v6 --insecure
			fi
		else
			if [[ "$BT" = "false" ]]; then
				~/.acme.sh/acme.sh   --issue -d $DOMAIN --keylength ec-256 --pre-hook "systemctl stop nginx" --post-hook "systemctl restart nginx"  --standalone --insecure
			else
				~/.acme.sh/acme.sh   --issue -d $DOMAIN --keylength ec-256 --pre-hook "nginx -s stop || { echo -n ''; }" --post-hook "nginx -c /www/server/nginx/conf/nginx.conf || { echo -n ''; }"  --standalone --insecure
			fi
		fi		
		
        [[ -f ~/.acme.sh/${DOMAIN}_ecc/ca.cer ]] || {
            colorEcho $RED " 获取证书失败，请截图到TG群反馈"
            exit 1
        }
        KEY_FILE="/etc/v2ray/${DOMAIN}.key"
		CERT_FILE="/etc/v2ray/${DOMAIN}.pem"
        ~/.acme.sh/acme.sh  --install-cert -d $DOMAIN --ecc \
            --key-file       $KEY_FILE  \
            --fullchain-file $CERT_FILE \
            --reloadcmd     "service nginx force-reload"
        [[ -f $CERT_FILE && -f $KEY_FILE ]] || {
            colorEcho $RED " 获取证书失败，请截图到TG群反馈"
            exit 1
        }
    else
        cp ~/v2ray.pem /etc/v2ray/${DOMAIN}.pem
        cp ~/v2ray.key /etc/v2ray/${DOMAIN}.key
    fi
}

configNginx() {
    mkdir -p /usr/share/nginx/html;
    if [[ "$ALLOW_SPIDER" = "n" ]]; then
        echo 'User-Agent: *' > /usr/share/nginx/html/robots.txt
        echo 'Disallow: /' >> /usr/share/nginx/html/robots.txt
        ROBOT_CONFIG="    location = /robots.txt {}"
    else
        ROBOT_CONFIG=""
    fi

    if [[ "$BT" = "false" ]]; then
        if [[ ! -f /etc/nginx/nginx.conf.bak ]]; then
            mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
        fi
        res=`id nginx 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            user="www-data"
        else
            user="nginx"
        fi
        cat > /etc/nginx/nginx.conf<<-EOF
user $user;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    server_tokens off;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    gzip                on;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;
}
EOF
    fi

    if [[ "$PROXY_URL" = "" ]]; then
        action=""
    else
        action="proxy_ssl_server_name on;
        proxy_pass $PROXY_URL;
        proxy_set_header Accept-Encoding '';
        sub_filter \"$REMOTE_HOST\" \"$DOMAIN\";
        sub_filter_once off;"
    fi

    if [[ "$TLS" = "true" || "$XTLS" = "true" ]]; then
        mkdir -p $NGINX_CONF_PATH
        # VMESS+WS+TLS
        # VLESS+WS+TLS
        if [[ "$WS" = "true" ]]; then
            cat > ${NGINX_CONF_PATH}${DOMAIN}.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};
    return 301 https://\$server_name:${PORT}\$request_uri;
}

server {
    listen       ${PORT} ssl http2;
    listen       [::]:${PORT} ssl http2;
    server_name ${DOMAIN};
    charset utf-8;

    # ssl配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
    
    ssl_prefer_server_ciphers on;
    ssl_session_cache builtin:1000 shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_buffer_size 1400;
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_session_tickets off;
    ssl_certificate $CERT_FILE;
    ssl_certificate_key $KEY_FILE;

    root /usr/share/nginx/html;
    location / {
        $action
    }
    $ROBOT_CONFIG

    location ${WSPATH} {
      proxy_redirect off;
      proxy_pass http://127.0.0.1:${V2PORT};
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$host;
      # Show real IP in v2ray access.log
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
        else
            # VLESS+TCP+TLS
            # VLESS+TCP+XTLS
            # trojan
            cat > ${NGINX_CONF_PATH}${DOMAIN}.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    listen 81 http2;
    server_name ${DOMAIN};
    root /usr/share/nginx/html;
    location / {
        $action
    }
    $ROBOT_CONFIG
}
EOF
        fi
    fi
}

setSelinux() {
    if [[ -s /etc/selinux/config ]] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
        setenforce 0
    fi
}

setFirewall() {
    res=`which firewall-cmd 2>/dev/null`
    if [[ $? -eq 0 ]]; then
        systemctl status firewalld > /dev/null 2>&1
        if [[ $? -eq 0 ]];then
            firewall-cmd --permanent --add-service=http
            firewall-cmd --permanent --add-service=https
            if [[ "$PORT" != "443" ]]; then
                firewall-cmd --permanent --add-port=${PORT}/tcp
                firewall-cmd --permanent --add-port=${PORT}/udp
            fi
            firewall-cmd --reload
        else
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport 80 -j ACCEPT
                iptables -I INPUT -p tcp --dport 443 -j ACCEPT
                if [[ "$PORT" != "443" ]]; then
                    iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                    iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
                fi
            fi
        fi
    else
        res=`which iptables 2>/dev/null`
        if [[ $? -eq 0 ]]; then
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport 80 -j ACCEPT
                iptables -I INPUT -p tcp --dport 443 -j ACCEPT
                if [[ "$PORT" != "443" ]]; then
                    iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                    iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
                fi
            fi
        else
            res=`which ufw 2>/dev/null`
            if [[ $? -eq 0 ]]; then
                res=`ufw status | grep -i inactive`
                if [[ "$res" = "" ]]; then
                    ufw allow http/tcp
                    ufw allow https/tcp
                    if [[ "$PORT" != "443" ]]; then
                        ufw allow ${PORT}/tcp
                        ufw allow ${PORT}/udp
                    fi
                fi
            fi
        fi
    fi
}

installV2ray() {
    rm -rf /tmp/v2ray
    mkdir -p /tmp/v2ray
    DOWNLOAD_LINK="https://github.com/v2fly/v2ray-core/releases/download/${NEW_VER}/v2ray-linux-$(archAffix).zip"
    colorEcho $BLUE " 下载V2Ray: ${DOWNLOAD_LINK}"
    curl -L -H "Cache-Control: no-cache" -o /tmp/v2ray/v2ray.zip ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        colorEcho $RED " 下载V2ray文件失败，请检查服务器网络设置"
        exit 1
    fi
    v2ray_start_config="run -c"
    mkdir -p '/etc/v2ray' '/var/log/v2ray' && \
    unzip /tmp/v2ray/v2ray.zip -d /tmp/v2ray
    mkdir -p /usr/bin/v2ray
    cp /tmp/v2ray/v2ray /usr/bin/v2ray/; cp /tmp/v2ray/geo* /usr/bin/v2ray/;
    chmod +x '/usr/bin/v2ray/v2ray' || {
    colorEcho $RED " V2ray安装失败"
    exit 1
    }
    if [[ "$NEW_VER" = "v4.32.1" ]]; then
	cp /tmp/v2ray/v2ctl /usr/bin/v2ray/;
	chmod +x '/usr/bin/v2ray/v2ctl' || {
        colorEcho $RED " V2ray安装失败"
        exit 1
	}
	v2ray_start_config="-config"
    fi

    cat >$SERVICE_FILE<<-EOF
[Unit]
Description=V2ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
NoNewPrivileges=true
ExecStart=/usr/bin/v2ray/v2ray $v2ray_start_config /etc/v2ray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable v2ray.service
}

trojanConfig() {
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "trojan",
    "settings": {
      "clients": [
        {
          "password": "$PASSWORD"
        }
      ],
      "fallbacks": [
        {
              "alpn": "http/1.1",
              "dest": 80
          },
          {
              "alpn": "h2",
              "dest": 81
          }
      ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
            "serverName": "$DOMAIN",
            "alpn": ["http/1.1", "h2"],
            "certificates": [
                {
                    "certificateFile": "$CERT_FILE",
                    "keyFile": "$KEY_FILE"
                }
            ]
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

trojanXTLSConfig() {
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "trojan",
    "settings": {
      "clients": [
        {
          "password": "$PASSWORD",
          "flow": "$FLOW"
        }
      ],
      "fallbacks": [
          {
              "alpn": "http/1.1",
              "dest": 80
          },
          {
              "alpn": "h2",
              "dest": 81
          }
      ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
            "serverName": "$DOMAIN",
            "alpn": ["http/1.1", "h2"],
            "certificates": [
                {
                    "certificateFile": "$CERT_FILE",
                    "keyFile": "$KEY_FILE"
                }
            ]
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vmessConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 1,
          "alterId": 0
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vmessKCPConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 1,
          "alterId": 0
        }
      ]
    },
    "streamSettings": {
        "network": "mkcp",
        "kcpSettings": {
            "uplinkCapacity": 100,
            "downlinkCapacity": 100,
            "congestion": true,
            "header": {
                "type": "$HEADER_TYPE"
            },
            "seed": "$SEED"
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vmessTLSConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 1,
          "alterId": 0
        }
      ],
      "disableInsecureEncryption": false
    },
    "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
            "serverName": "$DOMAIN",
            "alpn": ["http/1.1", "h2"],
            "certificates": [
                {
                    "certificateFile": "$CERT_FILE",
                    "keyFile": "$KEY_FILE"
                }
            ]
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vmessWSConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $V2PORT,
    "listen": "127.0.0.1",
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 1,
          "alterId": 0
        }
      ],
      "disableInsecureEncryption": false
    },
    "streamSettings": {
        "network": "ws",
        "wsSettings": {
            "path": "$WSPATH",
            "headers": {
                "Host": "$DOMAIN"
            }
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vlessTLSConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vless",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 0
        }
      ],
      "decryption": "none",
      "fallbacks": [
          {
              "alpn": "http/1.1",
              "dest": 80
          },
          {
              "alpn": "h2",
              "dest": 81
          }
      ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
            "serverName": "$DOMAIN",
            "alpn": ["http/1.1", "h2"],
            "certificates": [
                {
                    "certificateFile": "$CERT_FILE",
                    "keyFile": "$KEY_FILE"
                }
            ]
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vlessXTLSConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vless",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "flow": "$FLOW",
          "level": 0
        }
      ],
      "decryption": "none",
      "fallbacks": [
          {
              "alpn": "http/1.1",
              "dest": 80
          },
          {
              "alpn": "h2",
              "dest": 81
          }
      ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
            "serverName": "$DOMAIN",
            "alpn": ["http/1.1", "h2"],
            "certificates": [
                {
                    "certificateFile": "$CERT_FILE",
                    "keyFile": "$KEY_FILE"
                }
            ]
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vlessWSConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $V2PORT,
    "listen": "127.0.0.1",
    "protocol": "vless",
    "settings": {
        "clients": [
            {
                "id": "$uuid",
                "level": 0
            }
        ],
        "decryption": "none"
    },
    "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
            "path": "$WSPATH",
            "headers": {
                "Host": "$DOMAIN"
            }
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

vlessKCPConfig() {
    local uuid="$(cat '/proc/sys/kernel/random/uuid')"
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vless",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 0
        }
      ],
      "decryption": "none"
    },
    "streamSettings": {
        "streamSettings": {
            "network": "mkcp",
            "kcpSettings": {
                "uplinkCapacity": 100,
                "downlinkCapacity": 100,
                "congestion": true,
                "header": {
                    "type": "$HEADER_TYPE"
                },
                "seed": "$SEED"
            }
        }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

configV2ray() {
    mkdir -p /etc/v2ray
    if [[ "$TROJAN" = "true" ]]; then
        if [[ "$XTLS" = "true" ]]; then
            trojanXTLSConfig
        else
            trojanConfig
        fi
        return 0
    fi
    if [[ "$VLESS" = "false" ]]; then
        # VMESS + kcp
        if [[ "$KCP" = "true" ]]; then
            vmessKCPConfig
            return 0
        fi
        # VMESS
        if [[ "$TLS" = "false" ]]; then
            vmessConfig
        elif [[ "$WS" = "false" ]]; then
            # VMESS+TCP+TLS
            vmessTLSConfig
        # VMESS+WS+TLS
        else
            vmessWSConfig
        fi
    #VLESS
    else
        if [[ "$KCP" = "true" ]]; then
            vlessKCPConfig
            return 0
        fi
        # VLESS+TCP
        if [[ "$WS" = "false" ]]; then
            # VLESS+TCP+TLS
            if [[ "$XTLS" = "false" ]]; then
                vlessTLSConfig
            # VLESS+TCP+XTLS
            else
                vlessXTLSConfig
            fi
        # VLESS+WS+TLS
        else
            vlessWSConfig
        fi
    fi
}

#启动nginx
nginx() {
systemctl start nginx
}

#重启nginx
nginx2() {
systemctl restart nginx
}
install() {
	getData
	
    $PMT clean all
    [[ "$PMT" = "apt" ]] && $PMT update
    $CMD_INSTALL wget vim unzip tar gcc openssl curl sudo jp
    $CMD_INSTALL ruby qrencode psmisc
    $CMD_INSTALL libqrencode libqrencode-dev --fix-broken
    $CMD_INSTALL net-tools firewalld iptables ufw
    if [[ "$PMT" = "apt" ]]; then
        $CMD_INSTALL libssl-dev g++
    fi
res=$(which unzip 2>/dev/null)
if [[ $? -ne 0 ]]; then
    colorEcho $RED "unzip安装失败，请检查网络"
    exit 1
fi
    installNginx
    setFirewall
    if [[ "$TLS" = "true" || "$XTLS" = "true" ]]; then
        getCert
    fi
    configNginx

    colorEcho $BLUE " 安装V2ray..."
    getVersion
    RETVAL="$?"
    if [[ $RETVAL == 0 ]]; then
        colorEcho $BLUE " V2ray最新版 ${CUR_VER} 已经安装"
    elif [[ $RETVAL == 3 ]]; then
        exit 1
    else
        colorEcho $BLUE " 安装V2Ray ${NEW_VER} ，架构$(archAffix)"
        installV2ray
    fi

    configV2ray

    setSelinux
     
    start
    showInfo

}

update() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        colorEcho $RED " V2ray未安装，请先安装！"
        return
    fi

    getVersion
    RETVAL="$?"
    if [[ $RETVAL == 0 ]]; then
        colorEcho $BLUE " V2ray最新版 ${CUR_VER} 已经安装"
    elif [[ $RETVAL == 3 ]]; then
        exit 1
    else
        colorEcho $BLUE " 安装V2Ray ${NEW_VER} ，架构$(archAffix)"
        installV2ray
        stop
        start

        colorEcho $GREEN " 最新版V2ray安装成功！"
    fi
}

uninstall() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        colorEcho $RED " V2ray未安装，请先安装！"
        return
    fi

    echo ""
    read -p " 确定卸载V2ray？[y/n]：" answer
    if [[ "${answer,,}" = "y" ]]; then
        domain=`grep Host $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
        if [[ "$domain" = "" ]]; then
            domain=`grep serverName $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
        fi
        
        stop
        systemctl disable v2ray
        rm -rf $SERVICE_FILE
        rm -rf /etc/v2ray
        rm -rf /usr/bin/v2ray
        rm -rf /root/master.zip
        rm -rf /root/lolcat-master
        rm -rf /root/.acme.sh
		
        if [[ "$BT" = "false" ]]; then
            systemctl disable nginx
            $CMD_REMOVE nginx
            if [[ "$PMT" = "apt" ]]; then
                $CMD_REMOVE nginx-common
            fi
            rm -rf /etc/nginx/nginx.conf
            if [[ -f /etc/nginx/nginx.conf.bak ]]; then
                mv /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf
            fi
        fi
        if [[ "$domain" != "" ]]; then
            rm -rf $NGINX_CONF_PATH${domain}.conf
        fi
        [[ -f ~/.acme.sh/acme.sh ]] && ~/.acme.sh/acme.sh --uninstall
        colorEcho $GREEN " V2ray卸载成功"
    fi
}

start() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        colorEcho $RED " V2ray未安装，请先安装！"
        return
    fi
    stopNginx
    startNginx
    systemctl restart v2ray
    sleep 2
    port=`grep port $CONFIG_FILE| head -n 1| cut -d: -f2| tr -d \",' '`
    res=`ss -nutlp| grep ${port} | grep -i v2ray`
    if [[ "$res" = "" ]]; then
        colorEcho $RED " v2ray启动失败，请检查日志或查看端口是否被占用！"
    else
        colorEcho $BLUE " v2ray启动成功"
    fi
}

stop() {
    stopNginx
    systemctl stop v2ray
    colorEcho $BLUE " V2ray停止成功"
}

restart() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        colorEcho $RED " V2ray未安装，请先安装！"
        return
    fi

    stop
    start
}

getConfigFileInfo() {
    vless="false"
    tls="false"
    ws="false"
    xtls="false"
    trojan="false"
    protocol="VMess"
    kcp="false"

    uid=`grep id $CONFIG_FILE | head -n1| cut -d: -f2 | tr -d \",' '`
    alterid=`grep alterId $CONFIG_FILE  | cut -d: -f2 | tr -d \",' '`
    network=`grep network $CONFIG_FILE  | tail -n1| cut -d: -f2 | tr -d \",' '`
    [[ -z "$network" ]] && network="tcp"
    security=`grep security $CONFIG_FILE | head -n1 | cut -d: -f2 | tr -d \",' '`
    domain=`grep serverName $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
    if [[ "$domain" = "" ]]; then
        domain=`grep Host $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
        if [[ "$domain" != "" ]]; then
            ws="true"
            wspath=`grep path $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
        fi
    fi
    if [[ "$security" == "tls" ]] || [[ "$security" == "xtls" ]] || [[ "$security" == "reality" ]]; then
        tls="true"
        if [[ "$security" == "xtls" ]]; then
            xtls="true"
        fi
    fi
    if [[ "$domain" != "" ]] && [[ "$security" == "" ]]; then
        tls="true"
    fi
    if [[ "$ws" = "true" ]]; then
        port=`grep -i ssl $NGINX_CONF_PATH${domain}.conf| head -n1 | awk '{print $2}'`
    else
        port=`grep port $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
    fi
    res=`grep -i kcp $CONFIG_FILE`
    if [[ "$res" != "" ]]; then
        kcp="true"
        type=`grep header -A 3 $CONFIG_FILE | grep 'type' | cut -d: -f2 | tr -d \",' '`
        seed=`grep seed $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
    fi

    vmess=`grep vmess $CONFIG_FILE`
    if [[ "$vmess" = "" ]]; then
        trojan=`grep trojan $CONFIG_FILE`
        if [[ "$trojan" = "" ]]; then
            vless="true"
            protocol="VLESS"
        else
            trojan="true"
            password=`grep password $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
            protocol="trojan"
        fi
        tls="true"
        encryption="none"
        xtls=`grep xtlsSettings $CONFIG_FILE`
        if [[ "$xtls" != "" ]]; then
            xtls="true"
            flow=`grep flow $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
        else
            flow="无"
        fi
    fi
}

outputVmess() {
    raw="{
  \"v\":\"2\",
  \"ps\":\"${v4l}-${IP}-网路跳越\",
  \"add\":\"$IP\",
  \"port\":\"${port}\",
  \"id\":\"${uid}\",
  \"aid\":\"$alterid\",
  \"net\":\"tcp\",
  \"type\":\"none\",
  \"host\":\"\",
  \"path\":\"\",
  \"tls\":\"\"
}"
    link=`echo -n ${raw} | base64 -w 0`
    link="vmess://${link}"
mkdir -p /root/xray && echo $link > /root/xray/url.txt
    echo -e "   ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
    echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
    echo -e "   ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
    echo -e "   ${BLUE}额外id(alterid)：${PLAIN} ${RED}${alterid}${PLAIN}"
    echo -e "   ${BLUE}加密方式(security)：${PLAIN} ${RED}auto${PLAIN}"
    echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
    echo  
    echo -e "   ${BLUE}vmess链接:${PLAIN} $RED$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)	
}

outputVmessKCP() {
	echo -e "   ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
	echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
	echo -e "   ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
	echo -e "   ${BLUE}额外id(alterid)：${PLAIN} ${RED}${alterid}${PLAIN}"
	echo -e "   ${BLUE}加密方式(security)：${PLAIN} ${RED}auto${PLAIN}"
	echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
	echo -e "   ${BLUE}伪装类型(type)：${PLAIN} ${RED}${type}${PLAIN}"
	echo -e "   ${BLUE}mkcp seed：${PLAIN} ${RED}${seed}${PLAIN}"
}

outputTrojan() {
	if [[ "$xtls" == "true" ]]; then
		link="trojan://${password}@${domain}:${port}#${v4l}-${IP}-网路跳越-"
mkdir -p /root/xray && echo $link > /root/xray/url.txt		
		qrlink="https://api.qrserver.com/v1/create-qr-code/?data=${link}&size=300${link}"	
		echo -e "   ${BLUE}IP/域名(address): ${PLAIN} ${RED}${domain}${PLAIN}"
		echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
		echo -e "   ${BLUE}密码(password)：${PLAIN}${RED}${password}${PLAIN}"
		echo -e "   ${BLUE}流控(flow)：${PLAIN}$RED$flow${PLAIN}"
		echo -e "   ${BLUE}加密(encryption)：${PLAIN} ${RED}none${PLAIN}"
		echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
		echo -e "   ${BLUE}底层安全传输(tls)：${PLAIN}${RED}XTLS${PLAIN}"		
	echo	
	echo -e "   ${BLUE}Trojan链接: ${PLAIN}$YELLOW$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo		
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)				
	else
		link="trojan://${password}@${domain}:${port}#${v4l}-${IP}-网路跳越"
		mkdir -p /root/xray && echo $link > /root/xray/url.txt
		qrlink="https://api.qrserver.com/v1/create-qr-code/?data=${link}&size=300${link}"
		echo -e "   ${BLUE}IP/域名(address): ${PLAIN} ${RED}${domain}${PLAIN}"
		echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
		echo -e "   ${BLUE}密码(password)：${PLAIN}${RED}${password}${PLAIN}"
		echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
		echo -e "   ${BLUE}底层安全传输(tls)：${PLAIN}${RED}TLS${PLAIN}"
	echo	
	echo -e "   ${BLUE}Trojan链接: ${PLAIN}$YELLOW$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo		
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)				
	fi
}

outputVmessTLS() {
    raw="{
  \"v\":\"2\",
  \"ps\":\"${v4l}-${IP}-网路跳越\",
  \"add\":\"$IP\",
  \"port\":\"${port}\",
  \"id\":\"${uid}\",
  \"aid\":\"$alterid\",
  \"net\":\"${network}\",
  \"type\":\"none\",
  \"host\":\"${domain}\",
  \"path\":\"\",
  \"tls\":\"tls\"
}"
    link=`echo -n ${raw} | base64 -w 0`
    link="vmess://${link}"
	mkdir -p /root/xray && echo $link > /root/xray/url.txt
    echo -e "   ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
    echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
    echo -e "   ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
    echo -e "   ${BLUE}额外id(alterid)：${PLAIN} ${RED}${alterid}${PLAIN}"
    echo -e "   ${BLUE}加密方式(security)：${PLAIN} ${RED}none${PLAIN}"
    echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}" 
    echo -e "   ${BLUE}伪装域名/主机名(host)/SNI/peer名称：${PLAIN}${RED}${domain}${PLAIN}"
    echo -e "   ${BLUE}底层安全传输(tls)：${PLAIN}${RED}TLS${PLAIN}"
    echo  
    echo -e "   ${BLUE}vmess链接:${PLAIN} $RED$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)		
}

outputVmessWS() {
    raw="{
  \"v\":\"2\",
  \"ps\":\"${v4l}-${IP}-网路跳越\",
  \"add\":\"$IP\",
  \"port\":\"${port}\",
  \"id\":\"${uid}\",
  \"aid\":\"$alterid\",
  \"net\":\"${network}\",
  \"type\":\"none\",
  \"host\":\"${domain}\",
  \"path\":\"${wspath}\",
  \"tls\":\"tls\"
}"
    link=$(echo -n ${raw} | base64 -w 0)
    link="vmess://${link}"
mkdir -p /root/xray && echo $link > /root/xray/url.txt
    echo -e "   ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
    echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
    echo -e "   ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
    echo -e "   ${BLUE}额外id(alterid)：${PLAIN} ${RED}${alterid}${PLAIN}"
    echo -e "   ${BLUE}加密方式(security)：${PLAIN} ${RED}none${PLAIN}"
    echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}" 
    echo -e "   ${BLUE}伪装类型(type)：${PLAIN}${RED}none${PLAIN}"
    echo -e "   ${BLUE}伪装域名/主机名(host)/SNI/peer名称：${PLAIN}${RED}${domain}${PLAIN}"
    echo -e "   ${BLUE}路径(path)：${PLAIN}${RED}${wspath}${PLAIN}"
    echo -e "   ${BLUE}底层安全传输(tls)：${PLAIN}${RED}TLS${PLAIN}"
    echo  
    echo -e "   ${BLUE}vmess链接:${PLAIN} $RED$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)
}

showInfo() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        colorEcho $RED " V2ray未安装，请先安装！"
        return
    fi
    echo ""
    echo -n -e " ${BLUE}V2ray运行状态：${PLAIN}"
    statusText
    echo -e " ${BLUE}V2ray配置文件: ${PLAIN} ${RED}${CONFIG_FILE}${PLAIN}"
    colorEcho $BLUE " V2ray配置信息："
    getConfigFileInfo
    echo -e "   ${BLUE}节点备注:${v4l}-${IP}-网路跳越"
    echo -e "   ${BLUE}协议: ${PLAIN} ${RED}${protocol}${PLAIN}"
    if [[ "$trojan" = "true" ]]; then
        outputTrojan
        return 0
    fi
    if [[ "$vless" = "false" ]]; then
        if [[ "$kcp" = "true" ]]; then
            outputVmessKCP
            return 0
        fi
        if [[ "$tls" = "false" ]]; then
            outputVmess
        elif [[ "$ws" = "false" ]]; then
            outputVmessTLS
        else
            outputVmessWS
        fi
    else
        if [[ "$kcp" = "true" ]]; then
            echo -e "   ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
            echo -e "   ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
            echo -e "   ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
            echo -e "   ${BLUE}加密(encryption)：${PLAIN} ${RED}none${PLAIN}"
            echo -e "   ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
            echo -e "   ${BLUE}伪装类型(type)：${PLAIN} ${RED}${type}${PLAIN}"
            echo -e "   ${BLUE}mkcp seed：${PLAIN} ${RED}${seed}${PLAIN}" 
            return 0
        fi
		if [[ "$xtls" == "true" ]]; then
			echo -e " ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
			echo -e " ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
			echo -e " ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
			echo -e " ${BLUE}流控(flow)：${PLAIN}$RED$flow${PLAIN}"
			echo -e " ${BLUE}加密(encryption)：${PLAIN} ${RED}none${PLAIN}"
			echo -e " ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
			echo -e " ${BLUE}伪装类型(type)：${PLAIN}${RED}none$PLAIN"
			echo -e " ${BLUE}伪装域名/主机名(host)/SNI/peer名称：${PLAIN}${RED}${domain}${PLAIN}"
			echo -e " ${BLUE}底层安全传输(tls)：${PLAIN}${RED}XTLS${PLAIN}"
			# 通用格式(VLESS+TCP+xTLS)
			link="vless://${uid}@${domain}:${port}?encryption=none&security=xtls&type=tcp&host=${domain}&headerType=none#${v4l}-${IP}-网路跳越"
            mkdir -p /root/xray && echo $link > /root/xray/url.txt			
			qrlink="https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless%3A%2F%2F${uid}%40${domain}%3A${port}%3Fencryption%3Dnone%26security%3Dtls%26type%3Dtcp%26host%3D${domain}%26sni%3D${domain}%26path%3D${wspath}%23${Country}-${IP}-网路跳越"
				echo	
	echo -e "   ${BLUE}vless链接: ${PLAIN}$YELLOW$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码链接: ${PLAIN}$GREEN$qrlink$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo		
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)				
		elif [[ "$ws" == "false" ]]; then
			echo -e " ${BLUE}IP(address):  ${PLAIN}${RED}${IP}${PLAIN}"
			echo -e " ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
			echo -e " ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
			echo -e " ${BLUE}流控(flow)：${PLAIN}$RED$flow${PLAIN}"
			echo -e " ${BLUE}加密(encryption)：${PLAIN} ${RED}none${PLAIN}"
			echo -e " ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
			echo -e " ${BLUE}伪装类型(type)：${PLAIN}${RED}none$PLAIN"
			echo -e " ${BLUE}伪装域名/主机名(host)/SNI/peer名称：${PLAIN}${RED}${domain}${PLAIN}"
			echo -e " ${BLUE}底层安全传输(tls)：${PLAIN}${RED}TLS${PLAIN}"
			# 通用格式(VLESS+TCP+TLS)
			link="vless://${uid}@${domain}:${port}?encryption=none&security=tls&type=tcp&host=${domain}&headerType=none#${v4l}-${IP}-网路跳越"
			            mkdir -p /root/xray && echo $link > /root/xray/url.txt	
			qrlink="https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless%3A%2F%2F${uid}%40${domain}%3A${port}%3Fencryption%3Dnone%26security%3Dtls%26type%3Dtcp%26host%3D${domain}%26sni%3D${domain}%26path%3D${wspath}%23${Country}-${IP}-网路跳越"
	echo	
	echo -e "   ${BLUE}vless链接: ${PLAIN}$YELLOW$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码链接: ${PLAIN}$GREEN$qrlink$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo	
	    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)
		else
			echo -e " ${BLUE}IP(address): ${PLAIN} ${RED}${IP}${PLAIN}"
			echo -e " ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
			echo -e " ${BLUE}id(uuid)：${PLAIN}${RED}${uid}${PLAIN}"
			echo -e " ${BLUE}流控(flow)：${PLAIN}$RED$flow${PLAIN}"
			echo -e " ${BLUE}加密(encryption)：${PLAIN} ${RED}none${PLAIN}"
			echo -e " ${BLUE}传输协议(network)：${PLAIN} ${RED}${network}${PLAIN}"
			echo -e " ${BLUE}伪装类型(type)：${PLAIN}${RED}none$PLAIN"
			echo -e " ${BLUE}伪装域名/主机名(host)/SNI/peer名称：${PLAIN}${RED}${domain}${PLAIN}"
			echo -e " ${BLUE}路径(path)：${PLAIN}${RED}${wspath}${PLAIN}"
			echo -e " ${BLUE}底层安全传输(tls)：${PLAIN}${RED}TLS${PLAIN}"
			# 通用格式(VLESS+WS+TLS) 
			link="vless://${uid}@${domain}:${port}?encryption=none&security=tls&type=ws&host=${domain}&sni=${domain}&path=${wspath}#${v4l}-${IP}-网路跳越"
			            mkdir -p /root/xray && echo $link > /root/xray/url.txt	
			qrlink="https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless%3A%2F%2F${uid}%40${domain}%3A${port}%3Fencryption%3Dnone%26security%3Dtls%26type%3Dws%26host%3D${domain}%26sni%3D${domain}%26path%3D${wspath}%23${Country}-${IP}-网路跳越"
	echo	
	echo -e "   ${BLUE}vless链接: ${PLAIN}$YELLOW$(cat /root/xray/url.txt)$PLAIN"
	echo
	echo -e "   ${BLUE}二维码链接: ${PLAIN}$GREEN$qrlink$PLAIN"
	echo
	echo -e "   ${BLUE}二维码图片想下载位置是/root/xray-${IP}-网路跳越.png${PLAIN}必须是下载后查看，不能直接打开"
	echo		
    qrencode -t ANSIUTF8 -s 1 $(cat /root/xray/url.txt)
    qrencode -o ~/xray-${IP}-网路跳越.png -s 50 $(cat /root/xray/url.txt)		
		fi
	fi
}

showLog() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        colorEcho $RED " V2ray未安装，请先安装！"
        return
    fi

    journalctl -xen -u v2ray --no-pager
}

menu() {
	clear
	echo "#———————————————————————————————————————————————————————————#"	
	echo -e "#                     ${RED}v2ray一键安装脚本${PLAIN}                      #"
    echo -e "# ${GREEN}作者${PLAIN}: 网络跳越(sldm)                                      #"
    echo -e "# ${GREEN}导航${PLAIN}: https://www.wltysh.cn                            #"
 echo   	
echo -e "${GREEN}系统${PLAIN}：${BLUE}${OS}${PLAIN}"
echo -e "${GREEN}虚拟化${PLAIN}：${BLUE}${virtual}${PLAIN}"
echo -e "${GREEN}内核${PLAIN}：${BLUE}${kern}${PLAIN}"
	echo " ————————————————————————————————————————————————————————————"
    echo -e "再次运行输入 V 即可调用本脚本"
    echo " -----VMESS--------"	
    echo -e "  ${GREEN}1.${PLAIN}   安装V2ray-VMESS"
    echo -e "  ${GREEN}2.${PLAIN}   安装V2ray-${BLUE}VMESS+mKCP${PLAIN}"
    echo -e "  ${GREEN}3.${PLAIN}   安装V2ray-VMESS+TCP+TLS"
    echo -e "  ${GREEN}4.${PLAIN}   安装V2ray-${BLUE}VMESS+WS+TLS${PLAIN}${RED}(推荐)${PLAIN}"
    echo " ------VLESS-------"    
    echo -e "  ${GREEN}5.${PLAIN}   安装V2ray-${BLUE}VLESS+mKCP${PLAIN}"
    echo -e "  ${GREEN}6.${PLAIN}   安装V2ray-VLESS+TCP+TLS"
    echo -e "  ${GREEN}7.${PLAIN}   安装V2ray-${BLUE}VLESS+WS+TLS${PLAIN}${RED}(可过cdn)${PLAIN}"
    echo -e "  ${GREEN}8.${PLAIN}   安装V2ray-${BLUE}VLESS+TCP+XTLS${PLAIN}${RED}(推荐)${PLAIN}"
    echo " ------trojan-------"   
    echo -e "  ${GREEN}9.${PLAIN}   安装${BLUE}trojan${PLAIN}${RED}(推荐)${PLAIN}"
    echo -e "  ${GREEN}10.${PLAIN}  安装${BLUE}trojan+XTLS${PLAIN}${RED}(推荐)${PLAIN}"
    echo " -------------"
    echo -e "  ${GREEN}11.${PLAIN}  更新V2ray"
    echo -e "  ${GREEN}12.  ${RED}  卸载V2ray${PLAIN}"
    echo " -------------"
    echo -e "  ${GREEN}13.${PLAIN}  启动V2ray"
    echo -e "  ${GREEN}14.${PLAIN}  重启V2ray"
    echo -e "  ${GREEN}15.${PLAIN}  停止V2ray"
    echo " -------------"
    echo -e "  ${GREEN}16.${PLAIN}  查看V2ray配置"
    echo -e "  ${GREEN}17.${PLAIN}  查看V2ray日志"
	echo " ——————————————"
	echo -e "  ${GREEN}18.${PLAIN}  启动nginx"
	echo -e "  ${GREEN}19.${PLAIN}  重启nginx"
	echo " ——————————————"
    echo -e "  ${GREEN}0.${PLAIN}   退出"
    echo -n " 当前状态："
    statusText
	echo " ——————————————"
    read -p " 请选择操作[0-19]：" answer
    case $answer in
		0) exit 1 ;;
		1) install ;;
		2) KCP="true" && install ;;
		3) TLS="true" && install ;;
		4) TLS="true" && WS="true" && install ;;
		5) VLESS="true" && KCP="true" && install ;;
		6) VLESS="true" && TLS="true" && install ;;
		7) VLESS="true" && TLS="true" && WS="true" && install ;;
		8) VLESS="true" && TLS="true" && XTLS="true" && install ;;
		9) TROJAN="true" && TLS="true" && install ;;
		10) TROJAN="true" && TLS="true" && XTLS="true" && install ;;
		11) update ;;
		12) uninstall ;;
		13) start ;;
		14) restart ;;
		15) stop ;;
		16) showInfo ;;
		17) showLog ;;
		18) nginx ;;
		19) nginx2 ;;
        *)
            colorEcho $RED " 请选择正确的操作！"
            exit 1
            ;;
    esac
}

checkSystem

action=$1
[[ -z $1 ]] && action=menu
case "$action" in
    menu|update|uninstall|start|restart|stop|showInfo|showLog)
        ${action}
        ;;
    *)
        echo " 参数错误"
        echo " 用法: `basename $0` [menu|update|uninstall|start|restart|stop|showInfo|showLog]"
        ;;
esac
}

REALITYy() {
# REALITY一键安装脚本

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

# 设置全局快捷键
cp -f "$0" /usr/local/bin/R
chmod +x /usr/local/bin/R
# 设置全局快捷键
cp -f "$0" /usr/local/bin/r
chmod +x /usr/local/bin/r

colorEcho() {
    echo -e "${1}${@:2}${PLAIN}"
}

checkSystem() {
    result=$(id | awk '{print $1}')
    if [[ $result != "uid=0(root)" ]]; then
        colorEcho $RED " 请以root身份执行该脚本"
        exit 1
    fi

    res=`which yum 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        res=`which apt 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " 不受支持的Linux系统"
            exit 1
        fi
        PMT="apt"
        CMD_INSTALL="apt install -y "
        CMD_REMOVE="apt remove -y "
        CMD_UPGRADE="apt update; apt upgrade -y; apt autoremove -y"
    else
        PMT="yum"
        CMD_INSTALL="yum install -y "
        CMD_REMOVE="yum remove -y "
        CMD_UPGRADE="yum update -y"
    fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " 系统版本过低，请升级到最新版本"
        exit 1
    fi
}



status_singbox() {
    export PATH=/usr/local/bin:$PATH
    cmd="$(command -v /root/sing-box)"
    if [[ "$cmd" = "" ]]; then
        echo 0
        return
    fi
    if [[ ! -f /root/reality.json ]]; then
        echo 1
        return
    fi
	
	port=`grep -o '"listen_port": [0-9]*' /root/reality.json | awk '{print $2}'`
	if [[ -n "$port" ]]; then
        res=`ss -ntlp| grep ${port} | grep sing-box`
        if [[ -z "$res" ]]; then
            echo 2
        else
            echo 3
        fi
	else
	    echo 2
	fi
	
}

statusText_singbox() {
    res=`status_singbox`
    case $res in
        2)
            echo -e ${GREEN}已安装singbox${PLAIN} ${RED}未运行${PLAIN}
            ;;
        3)
            echo -e ${GREEN}已安装singbox${PLAIN} ${GREEN}正在运行${PLAIN}
            ;;
        *)
            echo -e ${RED}未安装singbox${PLAIN}
            ;;
    esac
}

preinstall() {
    $PMT clean all
    [[ "$PMT" = "apt" ]] && $PMT update
    echo ""
    echo "安装必要软件，请等待..."
    if [[ "$PMT" = "apt" ]]; then
		res=`which ufw 2>/dev/null`
        [[ "$?" != "0" ]] && $CMD_INSTALL ufw
	fi	
    res=`which curl 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL curl
    res=`which openssl 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL openssl
	res=`which qrencode 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL qrencode
	res=`which jq 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL jq

    if [[ -s /etc/selinux/config ]] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
        setenforce 0
    fi
}

# 定义函数，返回随机选择的域名
random_website() {
    domains=(
        "one-piece.com"
        "www.lovelive-anime.jp"
        "www.swift.com"
        "academy.nvidia.com"
        "www.cisco.com"
        "www.samsung.com"
        "www.amd.com"
        "www.apple.com"
        "music.apple.com"
        "www.amazon.com"		
        "www.fandom.com"
        "tidal.com"
        "zoro.to"
        "www.pixiv.co.jp"
        "mxj.myanimelist.net"
        "mora.jp"
        "www.j-wave.co.jp"
        "www.dmm.com"
        "booth.pm"
        "www.ivi.tv"
        "www.leercapitulo.com"
        "www.sky.com"
        "itunes.apple.com"
        "download-installer.cdn.mozilla.net"	
    )

    total_domains=${#domains[@]}
    random_index=$((RANDOM % total_domains))
    echo "${domains[random_index]}"
}
# 安装 singbox内核
installSingbox() {
	echo ""
	echo "正在安装稳定版..."
	latest_version_tag=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases" | jq -r '[.[] | select(.prerelease==false)][0].tag_name')
	latest_version=${latest_version_tag#v}  # 移除版本号前的 'v'
	arch=$(uname -m)
	
	# 映射架构名称
	case ${arch} in
		x86_64)
			arch="amd64"
			;;
		aarch64)
			arch="arm64"
			;;
		armv7l)
			arch="armv7"
			;;
	esac
    package_name="sing-box-${latest_version}-linux-${arch}"
    url="https://github.com/SagerNet/sing-box/releases/download/${latest_version_tag}/${package_name}.tar.gz"
    curl -sLo "/root/${package_name}.tar.gz" "$url"
    tar -xzf "/root/${package_name}.tar.gz" -C /root
    mv "/root/${package_name}/sing-box" /root/
    rm -r "/root/${package_name}.tar.gz" "/root/${package_name}"

    # 设置权限
    chown root:root /root/sing-box
    chmod +x /root/sing-box
	mkdir -p /root/singbox
	touch /root/reality.json
    colorEcho $BLUE "已安装最新稳定版 $latest_version"
	sleep 5
}

install_singbox() {

    # Generate uuid
	echo ""
    echo "正在生成UUID..."
	/root/sing-box generate uuid > /root/singbox/uuid
    uuid=`cat /root/singbox/uuid`
    colorEcho $BLUE "UUID：$uuid"
	echo ""
	read -p "请输入您的节点名称，如果留空将保持默认：" node_name
	[[ -z "$node_name" ]] && node_name="Reality(by网络跳越)"
    colorEcho $BLUE "节点名称：$node_name"
	echo "$node_name" > /root/singbox/name
	echo ""
    echo "正在生成私钥和公钥，请妥善保管好..."
	key_pair=$(/root/sing-box generate reality-keypair)
	private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')
	public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')
    colorEcho $BLUE "$private_key"
    colorEcho $BLUE "$public_key"
	echo "$public_key" | base64 > /root/public.key.b64
	echo ""
	# 尝试获取 IP 地址
    LOCAL_IPv4=$(curl -s -4 https://api.ipify.org)
    LOCAL_IPv6=$(curl -s -6 https://api64.ipify.org)
    # 检查 IPv是否存在且合法
    if [[ -n "$LOCAL_IPv4" && "$LOCAL_IPv4" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        if [[ -n "$LOCAL_IPv6" && "$LOCAL_IPv6" =~ ^([0-9a-fA-F:]+)$ ]]; then
            colorEcho $YELLOW "本机 IPv4 地址："$LOCAL_IPv4""		    
            colorEcho $YELLOW "本机 IPv6 地址："$LOCAL_IPv6""
	        read -p "请确定你的节点ip，默认ipv4（0：ipv4；1：ipv6）:" USER_IP
	        if [[ $USER_IP == 1 ]]; then
                server_ip=$LOCAL_IPv6
	            colorEcho $BLUE "节点ip："$server_ip""				
            else
                server_ip=$LOCAL_IPv4
	            colorEcho $BLUE "节点ip："$server_ip""						
            fi								
        else
		    colorEcho $YELLOW "本机仅有 IPv4 地址："$LOCAL_IPv4""		
		    server_ip=$LOCAL_IPv4
            colorEcho $BLUE "节点ip："$server_ip""
        fi
    else
	    if [[ -n "$LOCAL_IPv6" && "$LOCAL_IPv6" =~ ^([0-9a-fA-F:]+)$ ]]; then
	        colorEcho $YELLOW "本机仅有 IPv6 地址："$LOCAL_IPv6""		
		    server_ip=$LOCAL_IPv6
            colorEcho $BLUE "节点ip："$server_ip""
		else
            colorEcho $RED "未能获取到有效的公网 IP 地址。"		
		fi
    fi
    echo "$server_ip" > /root/singbox/ip
	echo ""
    while true
    do
        read -p "请设置singbox的端口号[1025-65535]，不输入则随机生成:" listen_port
        [[ -z "$listen_port" ]] && listen_port=`shuf -i1025-65000 -n1`
        if [[ "${listen_port:0:1}" = "0" ]]; then
            echo -e "${RED}端口不能以0开头${PLAIN}"
            exit 1
        fi
        expr $listen_port + 0 &>/dev/null
        if [[ $? -eq 0 ]]; then
            if [[ $listen_port -ge 1025 ]] && [[ $listen_port -le 65535 ]]; then
	            echo "$listen_port" > /root/singbox/port				
                colorEcho $BLUE "端口号：$listen_port"
                break
            else
                colorEcho $RED "输入错误，端口号为1025-65535的数字"
            fi
        else
            colorEcho $RED "输入错误，端口号为1025-65535的数字"
        fi
    done
	echo ""
	echo "正在开启$listen_port端口..."	
    if [ -x "$(command -v firewall-cmd)" ]; then							  
        firewall-cmd --permanent --add-port=${listen_port}/tcp > /dev/null 2>&1
        firewall-cmd --permanent --add-port=${listen_port}/udp > /dev/null 2>&1
        firewall-cmd --reload > /dev/null 2>&1
		colorEcho $YELLOW "$listen_port端口已成功开启"
	elif [ -x "$(command -v ufw)" ]; then								  
        ufw allow ${listen_port}/tcp > /dev/null 2>&1
        ufw allow ${listen_port}/udp > /dev/null 2>&1
	    ufw reload > /dev/null 2>&1
		colorEcho $YELLOW "$listen_port端口已成功开启"
    else
	    colorEcho $RED "无法配置防火墙规则。请手动配置以确保新singbox端口可用!"
    fi
    echo ""
    read -p "请输入您的 dest 地址并确保该域名在国内的连通性（例如：www.amazon.com），如果留空将随机生成：" DEST
	if [[ -z "$DEST" ]]; then
		while true; do
			domain=$(random_website)
			check_num=$(echo QUIT | stdbuf -oL openssl s_client -connect "${domain}:443" -tls1_3 -alpn h2 2>&1 | grep -Eoi '(TLSv1.3)|(^ALPN\s+protocol:\s+h2$)|(X25519)' | sort -u | wc -l)
			if [ "$check_num" -eq 3 ]; then
				DEST="$domain"
				break
			fi
		done
	    echo $DEST > /root/singbox/dest		
		echo $DEST > /root/singbox/servername
	    server_name=`cat /root/singbox/servername`
		colorEcho $BLUE "选中的符合条件的网站是： $server_name"	
	else
		echo "正在检查 \"${DEST}\" 是否支持 TLSv1.3与h2"
        check_num=$(echo QUIT | stdbuf -oL openssl s_client -connect "${DEST}:443" -tls1_3 -alpn h2 2>&1 | grep -Eoi '(TLSv1.3)|(^ALPN\s+protocol:\s+h2$)|(X25519)' | sort -u | wc -l)
		if [[ ${check_num} -eq 3 ]]; then
			echo $DEST > /root/singbox/dest		
		    echo $DEST > /root/singbox/servername
	        server_name=`cat /root/singbox/servername`
			colorEcho $YELLOW "目标网址：\"${DEST}\" 支持 TLSv1.3 与 h2"
		else
			colorEcho $YELLOW "目标网址：\"${DEST}\" 不支持 TLSv1.3 与 h2，将在默认域名组中随机挑选域名"
			while true; do
				domain=$(random_website)
				check_num=$(echo QUIT | stdbuf -oL openssl s_client -connect "${domain}:443" -tls1_3 -alpn h2 2>&1 | grep -Eoi '(TLSv1.3)|(^ALPN\s+protocol:\s+h2$)|(X25519)' | sort -u | wc -l)
				if [ "$check_num" -eq 3 ]; then
					DEST="$domain"
					break
				fi
			done
			echo $DEST > /root/singbox/dest		
			echo $DEST > /root/singbox/servername
			server_name=`cat /root/singbox/servername`
			colorEcho $BLUE "选中的符合条件的网站是： $server_name"				
		fi	   
	fi	
	echo ""
    echo "正在生成shortID..." 
    /root/sing-box generate rand --hex 8 > /root/singbox/sid
    short_id=`cat /root/singbox/sid`
    colorEcho $BLUE  "shortID：$short_id"
	echo ""
jq -n --arg listen_port "$listen_port" --arg server_name "$server_name" --arg private_key "$private_key" --arg short_id "$short_id" --arg uuid "$uuid" --arg server_ip "$server_ip" '{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": ($listen_port | tonumber),
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "ipv4_only",
      "users": [
        {
          "uuid": $uuid,
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": $server_name,
          "reality": {
          "enabled": true,
          "handshake": {
            "server": $server_name,
            "server_port": 443
          },
          "private_key": $private_key,
          "short_id": [$short_id]
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}' > /root/reality.json

cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/root/sing-box run -c /root/reality.json
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

if /root/sing-box check -c /root/reality.json; then
    echo "所有配置完成，正在启动singbox程序..."
    systemctl daemon-reload
    systemctl enable sing-box > /dev/null 2>&1
    systemctl start sing-box
    systemctl restart sing-box
	if [[ "$server_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        server_link="vless://$uuid@$server_ip:$listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#$node_name"
	elif [[ "$server_ip" =~ ^([0-9a-fA-F:]+)$ ]]; then 
        server_link="vless://$uuid@[$server_ip]:$listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#$node_name"
	else
	    colorEcho $RED "没有获取到有效ip！"
	fi
    echo ""
    colorEcho $BLUE "reality节点配置信息如下："
    colorEcho $YELLOW "Server IP: ${PLAIN}$server_ip"
    colorEcho $YELLOW "Listen Port: ${PLAIN}$listen_port"
    colorEcho $YELLOW "Server Name: ${PLAIN}$server_name"
    colorEcho $YELLOW "Public Key: ${PLAIN}$public_key"
    colorEcho $YELLOW "Short ID: ${PLAIN}$short_id"
    colorEcho $YELLOW "UUID: ${PLAIN}$uuid"
    echo ""
    echo ""
    colorEcho $BLUE "${BLUE}reality订阅链接${PLAIN}：${server_link}"	
	echo ""
    echo ""
	colorEcho $YELLOW "reality节点二维码（可直接扫码导入到v2rayN、shadowrocket等客户端...）："
	qrencode -o - -t utf8 -s 1 ${server_link}
    echo ""
    echo ""
else
    colorEcho $RED "配置错误."
fi
}

reinstallSingbox() {
    colorEcho $BLUE "正在重新安装..."
	systemctl stop sing-box
	systemctl disable sing-box > /dev/null 2>&1
	rm /etc/systemd/system/sing-box.service
	rm /root/reality.json
	rm /root/sing-box
	rm /root/public.key.b64
	rm -rf /root/singbox
}

Switch_singboxcore() {
	echo ""
	echo "更新singbox内核..."
	current_version_tag=$(/root/sing-box version | grep 'sing-box version' | awk '{print $3}')
	latest_stable_version=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases" | jq -r '[.[] | select(.prerelease==false)][0].tag_name')
    if [[ $current_version_tag == *"-alpha"* ]]; then
	    singbox_version="稳定版"
	fi
	colorEcho $YELLOW "当前已安装$singbox_version：$current_version_tag"
	colorEcho $BLUE "当前最新稳定版：$latest_stable_version"	
	echo ""
	echo 0. 保持不变	
	echo 1. 升级最新稳定版
	read -p "请输入你的选择（0-1）:" USER_CHOICE
	case $USER_CHOICE in 
		1)
			new_version_tag=$latest_stable_version
			singbox_version="稳定版"
			;;
		0)
			colorEcho $BLUE "保持不变"
			exit 0
			;;				
		*)
			new_version_tag=$latest_stable_version
			singbox_version="稳定版"
			;;
    esac
    res=`status_singbox`
    case $res in
        3)
	        systemctl stop sing-box 
            ;;
    esac
	arch=$(uname -m)
	case $arch in
		x86_64) arch="amd64" ;;
		aarch64) arch="arm64" ;;
		armv7l) arch="armv7" ;;
	esac
	package_name="sing-box-${new_version_tag#v}-linux-${arch}"
	url="https://github.com/SagerNet/sing-box/releases/download/${new_version_tag}/${package_name}.tar.gz"

	curl -sLo "/root/${package_name}.tar.gz" "$url"
	tar -xzf "/root/${package_name}.tar.gz" -C /root
	mv "/root/${package_name}/sing-box" /root/sing-box
	rm -r "/root/${package_name}.tar.gz" "/root/${package_name}"
	chown root:root /root/sing-box
	chmod +x /root/sing-box
	systemctl daemon-reload
    case $res in
        2)
	        systemctl start sing-box 
            ;;
    esac

	colorEcho $YELLOW "已更新到$singbox_version：$new_version_tag"
	echo ""
	sleep 5
}

UninstallSingbox() {
    echo "正在卸载singbox..."
    systemctl stop sing-box
    systemctl disable sing-box > /dev/null 2>&1
    rm -f /etc/systemd/system/sing-box.service
    rm -f /root/sing-box
    rm -f /root/reality.json
    rm -f /root/public.key.b64
    rm -rf /root/singbox
    systemctl daemon-reload
    colorEcho $GREEN "singbox 卸载完成"
}

Show_Link() {
	current_listen_port=$(jq -r '.inbounds[0].listen_port' /root/reality.json)
	current_server_name=$(jq -r '.inbounds[0].tls.server_name' /root/reality.json)
	uuid=$(jq -r '.inbounds[0].users[0].uuid' /root/reality.json)
	public_key=$(base64 --decode /root/public.key.b64)
	short_id=$(jq -r '.inbounds[0].tls.reality.short_id[0]' /root/reality.json)
	server_ip=$(cat /root/singbox/ip)
	if [[ "$server_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        server_link="vless://$uuid@$server_ip:$listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#$node_name"
	elif [[ "$server_ip" =~ ^([0-9a-fA-F:]+)$ ]]; then 
        server_link="vless://$uuid@[$server_ip]:$listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#$node_name"
	else
	    colorEcho $RED "没有获取到有效ip！"
	fi
    colorEcho $BLUE "${BLUE}reality订阅链接${PLAIN}：${server_link}"	
	echo ""
    echo ""
	colorEcho $YELLOW "reality节点二维码（可直接扫码导入到v2rayN、shadowrocket等客户端...）："
	qrencode -o - -t utf8 -s 1 ${server_link}
	exit 0
}

Modify_singboxconfig() {
	listen_port=$(jq -r '.inbounds[0].listen_port' /root/reality.json)
	server_name=$(jq -r '.inbounds[0].tls.server_name' /root/reality.json)
	uuid=$(jq -r '.inbounds[0].users[0].uuid' /root/reality.json)
	public_key=$(base64 --decode /root/public.key.b64)
	private_key=$(jq -r '.inbounds[0].tls.reality.private_key' /root/reality.json)
	short_id=$(jq -r '.inbounds[0].tls.reality.short_id[0]' /root/reality.json)
	server_ip=$(cat /root/singbox/ip)
	node_name=$(cat /root/singbox/name)
	echo ""
	read -p "是否需要重新生成UUID（0：保持不变；1：重新生成）:" new_uuid
	if [[ $new_uuid == 1 ]]; then
	    echo ""
		echo "正在重新生成UUID...:" uuid
		/root/sing-box generate uuid > /root/singbox/uuid
		uuid=`cat /root/singbox/uuid`
		colorEcho $BLUE "UUID：$uuid"
	else
	    colorEcho $BLUE "uuid保持不变!" 
	fi
	echo ""
	read -p "是否需要重新给节点命名（0：保持不变；1：重新命名）:" new_name
	if [[ $new_name == 1 ]]; then	
	    echo ""
		read -p "请输入您的节点名称，如果留空将保持默认：" node_name
		[[ -z "$node_name" ]] && node_name="Reality(by网络跳越)"
		colorEcho $BLUE "节点名称：$node_name"
		echo "$node_name" > /root/singbox/name
    else
	    colorEcho $BLUE "节点名称保持不变!" 
	fi
	echo ""
	read -p "是否需要重新生成密钥（0：保持不变；1：重新生成）:" new_key
	if [[ $new_key == 1 ]]; then
	    echo ""
        echo "正在重新生成私钥和公钥，请妥善保管好："
	    key_pair=$(/root/sing-box generate reality-keypair)
	    private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')
	    public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')
        colorEcho $BLUE "$private_key"
        colorEcho $BLUE "$public_key"
	    echo "$public_key" | base64 > /root/public.key.b64		
	else
	    colorEcho $BLUE "密钥保持不变!" 
	fi
	echo ""
	read -p "是否需要更换节点ip（0：保持不变；1：重新选择）:" CHAIP
	if [[ $CHAIP == 1 ]]; then	
		LOCAL_IPv4=$(curl -s -4 https://api.ipify.org)
		LOCAL_IPv6=$(curl -s -6 https://api64.ipify.org)
		if [[ -n "$LOCAL_IPv4" && "$LOCAL_IPv4" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			if [[ -n "$LOCAL_IPv6" && "$LOCAL_IPv6" =~ ^([0-9a-fA-F:]+)$ ]]; then
				colorEcho $YELLOW "本机 IPv4 地址："$LOCAL_IPv4""		    
				colorEcho $YELLOW "本机 IPv6 地址："$LOCAL_IPv6""
				read -p "请确定你的节点ip，默认ipv4（0：ipv4；1：ipv6）:" USER_IP
				if [[ $USER_IP == 1 ]]; then
					server_ip=$LOCAL_IPv6
					colorEcho $BLUE "节点ip："$server_ip""				
				else
					server_ip=$LOCAL_IPv4
					colorEcho $BLUE "节点ip："$server_ip""						
				fi								
			else
				colorEcho $YELLOW "本机仅有 IPv4 地址："$LOCAL_IPv4""		
				server_ip=$LOCAL_IPv4
				colorEcho $BLUE "节点ip："$server_ip""
			fi
		else
			if [[ -n "$LOCAL_IPv6" && "$LOCAL_IPv6" =~ ^([0-9a-fA-F:]+)$ ]]; then
				colorEcho $YELLOW "本机仅有 IPv6 地址："$LOCAL_IPv6""		
				server_ip=$LOCAL_IPv6
				colorEcho $BLUE "节点ip："$server_ip""
			else
				colorEcho $RED "未能获取到有效的公网 IP 地址。"		
			fi
		fi
		echo "$server_ip" > /root/singbox/ip
    else
	    colorEcho $BLUE "节点ip保持不变!"  		
    fi
	echo ""
	read -p "是否需要更换端口（0：保持不变；1：更换端口）:" new_port
	if [[ $new_port == 1 ]]; then	
		while true
		do
		    echo ""
			read -p "请设置singbox的端口号[1025-65535]，不输入则随机生成:" listen_port
			[[ -z "$listen_port" ]] && listen_port=`shuf -i1025-65000 -n1`
			if [[ "${listen_port:0:1}" = "0" ]]; then
				echo -e "${RED}端口不能以0开头${PLAIN}"
				exit 1
			fi
			expr $listen_port + 0 &>/dev/null
			if [[ $? -eq 0 ]]; then
				if [[ $listen_port -ge 1025 ]] && [[ $listen_port -le 65535 ]]; then
					echo "$listen_port" > /root/singbox/port				
					colorEcho $BLUE "端口号：$listen_port"
					echo ""
					echo "正在开启$listen_port端口..."	
					if [ -x "$(command -v firewall-cmd)" ]; then							  
						firewall-cmd --permanent --add-port=${listen_port}/tcp > /dev/null 2>&1
						firewall-cmd --permanent --add-port=${listen_port}/udp > /dev/null 2>&1
						firewall-cmd --reload > /dev/null 2>&1
						colorEcho $YELLOW "$listen_port端口已成功开启"
					elif [ -x "$(command -v ufw)" ]; then								  
						ufw allow ${listen_port}/tcp > /dev/null 2>&1
						ufw allow ${listen_port}/udp > /dev/null 2>&1
						ufw reload > /dev/null 2>&1
						colorEcho $YELLOW "$listen_port端口已成功开启"
					else
						colorEcho $RED "无法配置防火墙规则。请手动配置以确保新singbox端口可用!"
					fi
					break
				else
					colorEcho $RED "输入错误，端口号为1025-65535的数字"
				fi
			else
				colorEcho $RED "输入错误，端口号为1025-65535的数字"
			fi
		done
	else
	    colorEcho $BLUE "端口保持不变!"  
	fi
	echo ""
	read -p "是否需要更换目标网站（0：保持不变；1：重新输入）:" new_sni
	if [[ $new_sni == 1 ]]; then	
		echo ""
		read -p "请输入您的 dest 地址并确保该域名在国内的连通性（例如：www.amazon.com），如果留空将随机生成：" DEST
		if [[ -z "$DEST" ]]; then
			while true; do
				domain=$(random_website)
				check_num=$(echo QUIT | stdbuf -oL openssl s_client -connect "${domain}:443" -tls1_3 -alpn h2 2>&1 | grep -Eoi '(TLSv1.3)|(^ALPN\s+protocol:\s+h2$)|(X25519)' | sort -u | wc -l)
				if [ "$check_num" -eq 3 ]; then
					DEST="$domain"
					break
				fi
			done
			echo $DEST > /root/singbox/dest		
			echo $DEST > /root/singbox/servername
			server_name=`cat /root/singbox/servername`
			colorEcho $BLUE "选中的符合条件的网站是： $server_name"	
		else
			echo "正在检查 \"${DEST}\" 是否支持 TLSv1.3与h2"
			check_num=$(echo QUIT | stdbuf -oL openssl s_client -connect "${DEST}:443" -tls1_3 -alpn h2 2>&1 | grep -Eoi '(TLSv1.3)|(^ALPN\s+protocol:\s+h2$)|(X25519)' | sort -u | wc -l)
			if [[ ${check_num} -eq 3 ]]; then
				echo $DEST > /root/singbox/dest		
				echo $DEST > /root/singbox/servername
				server_name=`cat /root/singbox/servername`
				colorEcho $YELLOW "目标网址：\"${DEST}\" 支持 TLSv1.3 与 h2"
			else
				colorEcho $YELLOW "目标网址：\"${DEST}\" 不支持 TLSv1.3 与 h2，将在默认域名组中随机挑选域名"
				while true; do
					domain=$(random_website)
					check_num=$(echo QUIT | stdbuf -oL openssl s_client -connect "${domain}:443" -tls1_3 -alpn h2 2>&1 | grep -Eoi '(TLSv1.3)|(^ALPN\s+protocol:\s+h2$)|(X25519)' | sort -u | wc -l)
					if [ "$check_num" -eq 3 ]; then
						DEST="$domain"
						break
					fi
				done
				echo $DEST > /root/singbox/dest		
				echo $DEST > /root/singbox/servername
				server_name=`cat /root/singbox/servername`
				colorEcho $BLUE "选中的符合条件的网站是： $server_name"				
			fi	   
		fi	
    else
	    colorEcho $BLUE"目标网址保持不变!"  
	fi
	echo ""
	read -p "是否需要重新生成shortID:（0：保持不变；1：重新生成）" new_sid
	if [[ $new_sid == 1 ]]; then	
	    echo ""
		echo "正在重新生成shortID..."
		/root/sing-box generate rand --hex 8 > /root/singbox/sid
		short_id=`cat /root/singbox/sid`
		colorEcho $BLUE  "shortID：$short_id"
	else
	    colorEcho $BLUE "shortID保持不变!"  
	fi
	echo ""
jq -n --arg listen_port "$listen_port" --arg server_name "$server_name" --arg private_key "$private_key" --arg short_id "$short_id" --arg uuid "$uuid" --arg server_ip "$server_ip" '{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": ($listen_port | tonumber),
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "ipv4_only",
      "users": [
        {
          "uuid": $uuid,
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": $server_name,
          "reality": {
          "enabled": true,
          "handshake": {
            "server": $server_name,
            "server_port": 443
          },
          "private_key": $private_key,
          "short_id": [$short_id]
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}' > /root/reality.json

	systemctl restart sing-box
	echo ""
	if [[ "$server_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        server_link="vless://$uuid@$server_ip:$listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#$node_name"
	elif [[ "$server_ip" =~ ^([0-9a-fA-F:]+)$ ]]; then 
        server_link="vless://$uuid@[$server_ip]:$listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#$node_name"
	else
	    colorEcho $RED "没有获取到有效ip！"
	fi
    colorEcho $BLUE "${BLUE}reality订阅链接${PLAIN}：${server_link}"	
	echo ""
    echo ""
	colorEcho $YELLOW "reality节点二维码（可直接扫码导入到v2rayN、shadowrocket等客户端...）："
	qrencode -o - -t utf8 -s 1 ${server_link}
	exit 0
}

setFirewall() {
    echo ""
	echo "正在开启$PORT端口..."	
    if [ -x "$(command -v firewall-cmd)" ]; then							  
        firewall-cmd --permanent --add-port=${PORT}/tcp > /dev/null 2>&1
        firewall-cmd --permanent --add-port=${PORT}/udp > /dev/null 2>&1
        firewall-cmd --reload > /dev/null 2>&1
		colorEcho $YELLOW "$PORT端口已成功开启"
	elif [ -x "$(command -v ufw)" ]; then								  
        ufw allow ${PORT}/tcp > /dev/null 2>&1
        ufw allow ${PORT}/udp > /dev/null 2>&1
	    ufw reload > /dev/null 2>&1
		colorEcho $YELLOW "$PORT端口已成功开启"
    else
	    echo "无法配置防火墙规则。请手动配置以确保新xray端口可用!"
    fi
}

start_singbox() {
    res=`status_singbox`
    if [[ $res -lt 2 ]]; then
        echo -e "${RED}singbox未安装，请先安装！${PLAIN}"
        return
    fi
    systemctl restart sing-box
    sleep 2
    port=`grep -o '"listen_port": [0-9]*' /root/reality.json | awk '{print $2}'`
    res=`ss -ntlp| grep ${port} | grep sing-box`
    if [[ "$res" = "" ]]; then
        colorEcho $RED "singbxo启动失败，请检查端口是否被占用！"
    else
        colorEcho $BLUE "singbox启动成功！"
    fi
}

restart_singbox() {
    res=`status_singbox`
    if [[ $res -lt 2 ]]; then
        echo -e "${RED}singbox未安装，请先安装！${PLAIN}"
        return
    fi
    stop_singbox
    start_singbox
}

stop_singbox() {
    res=`status_singbox`
    if [[ $res -lt 2 ]]; then
        echo -e "${RED}singbox未安装，请先安装！${PLAIN}"
        return
    fi
    systemctl stop sing-box
    colorEcho $BLUE "singbox停止成功"
}
	
Singbox() {
    clear
    echo "##################################################################"
    echo -e "# ${RED} Singbox -- Reality一键安装脚本${PLAIN}                                    #"
    echo -e "# ${GREEN}作者${PLAIN}: 网络跳越（hijk）                                                  #"	
    echo "##################################################################"
    echo -e "再次运行输入 r 即可调用本脚本"
    echo -e "  ${GREEN}  <Singbox内核版本>  ${YELLOW}"	
    echo -e "  ${GREEN}2.${PLAIN}  更新singbox"
    echo -e "  ${GREEN}3.${RED}  卸载singbox${PLAIN}"
    echo " -------------"		
	echo -e "  ${GREEN}4.${PLAIN}  搭建VLESS-Vision-uTLS-REALITY（singbox）"
    echo -e "  ${GREEN}5.${PLAIN}  查看reality链接"
    echo -e "  ${GREEN}6.  ${RED}修改reality配置${PLAIN}"		
    echo " -------------"
    echo -e "  ${GREEN}7.${PLAIN}  启动singbox"
    echo -e "  ${GREEN}8.${PLAIN}  重启singbox"
    echo -e "  ${GREEN}9.${PLAIN}  停止singbox"
    echo " -------------"
    echo -e "  ${GREEN}0.${PLAIN}  退出"
    echo -n " 当前singbox状态："
	statusText_singbox
    echo 

    read -p " 请选择操作[0-10]：" answer
    case $answer in
        0)
            exit 0
            ;;
        2)
            Switch_singboxcore
			Singbox
            ;;
        3)
            UninstallSingbox
            ;;
        4)  checkSystem
			preinstall
            installSingbox
            install_singbox
            ;;
        5)
			Show_Link  
            ;;
        6)
            Modify_singboxconfig     
            ;;			
        7)
            start_singbox
			Singbox
            ;;
        8)
            restart_singbox
			Singbox
            ;;
        9)
            stop_singbox
			Singbox
            ;;			
        *)
            echo " 请选择正确的操作！"
            exit 1
            ;;
    esac
}
Singbox
}

Hysteria2() {
export LANG=en_US.UTF-8

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

OS=$(hostnamectl | grep -i system | cut -d: -f2)
virtual=$(systemd-detect-virt)
 kern=$(uname -r)
#  识别国家
Country=$(curl -s4m8 https://ipinfo.io/country)
IP=$(curl -s4m8 ip.sb)
[[ "$?" != "0" ]] && IP=$(curl -s6m8 ip.sb )
#=====================
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora")
PACKAGE_UPDATE=("apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "yum -y install")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove" "yum -y remove")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove")

[[ $EUID -ne 0 ]] && red "注意: 请在root用户下运行脚本" && exit 1

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "目前暂不支持你的VPS的操作系统！" && exit 1

if [[ -z $(type -P curl) ]]; then
    if [[ ! $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_UPDATE[int]}
    fi
    ${PACKAGE_INSTALL[int]} curl
fi

realip(){
    ip=$(curl -s4m8 ip.sb -k) || ip=$(curl -s6m8 ip.sb -k)
}

inst_cert(){
    green "Hysteria 2 协议证书申请方式如下："
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 必应自签证书 ${YELLOW}（默认）${PLAIN}"
    echo -e " ${GREEN}2.${PLAIN} Acme 脚本自动申请"
    echo -e " ${GREEN}3.${PLAIN} 自定义证书路径"
    echo ""
    read -rp "请输入选项 [1-3]: " certInput
    if [[ $certInput == 2 ]]; then
        cert_path="/root/cert.crt"
        key_path="/root/private.key"

        chmod a+x /root # 让 Hysteria 主程序访问到 /root 目录

        if [[ -f /root/cert.crt && -f /root/private.key ]] && [[ -s /root/cert.crt && -s /root/private.key ]] && [[ -f /root/ca.log ]]; then
            domain=$(cat /root/ca.log)
            green "检测到原有域名：$domain 的证书，正在应用"
            hy_domain=$domain
        else
            WARPv4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
            WARPv6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
            if [[ $WARPv4Status =~ on|plus ]] || [[ $WARPv6Status =~ on|plus ]]; then
                wg-quick down wgcf >/dev/null 2>&1
                systemctl stop warp-go >/dev/null 2>&1
                realip
                wg-quick up wgcf >/dev/null 2>&1
                systemctl start warp-go >/dev/null 2>&1
            else
                realip
            fi
            
            read -p "请输入需要申请证书的域名：" domain
            [[ -z $domain ]] && red "未输入域名，无法执行操作！" && exit 1
            green "已输入的域名：$domain" && sleep 1
            domainIP=$(curl -sm8 ipget.net/?ip="${domain}")
            if [[ $domainIP == $ip ]]; then
                ${PACKAGE_INSTALL[int]} curl wget sudo socat openssl
                if [[ $SYSTEM == "CentOS" ]]; then
                    ${PACKAGE_INSTALL[int]} cronie
                    systemctl start crond
                    systemctl enable crond
                else
                    ${PACKAGE_INSTALL[int]} cron
                    systemctl start cron
                    systemctl enable cron
                fi
                curl https://get.acme.sh | sh -s email=$(date +%s%N | md5sum | cut -c 1-16)@gmail.com
                source ~/.bashrc
                bash ~/.acme.sh/acme.sh --upgrade --auto-upgrade
                bash ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
                if [[ -n $(echo $ip | grep ":") ]]; then
                    bash ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256 --listen-v6 --insecure
                else
                    bash ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256 --insecure
                fi
                bash ~/.acme.sh/acme.sh --install-cert -d ${domain} --key-file /root/private.key --fullchain-file /root/cert.crt --ecc
                if [[ -f /root/cert.crt && -f /root/private.key ]] && [[ -s /root/cert.crt && -s /root/private.key ]]; then
                    echo $domain > /root/ca.log
                    sed -i '/--cron/d' /etc/crontab >/dev/null 2>&1
                    echo "0 0 * * * root bash /root/.acme.sh/acme.sh --cron -f >/dev/null 2>&1" >> /etc/crontab
                    green "证书申请成功! 脚本申请到的证书 (cert.crt) 和私钥 (private.key) 文件已保存到 /root 文件夹下"
                    yellow "证书crt文件路径如下: /root/cert.crt"
                    yellow "私钥key文件路径如下: /root/private.key"
                    hy_domain=$domain
                fi
            else
                red "当前域名解析的IP与当前VPS使用的真实IP不匹配"
                green "建议如下："
                yellow "1. 请确保CloudFlare小云朵为关闭状态(仅限DNS), 其他域名解析或CDN网站设置同理"
                yellow "2. 请检查DNS解析设置的IP是否为VPS的真实IP"
                yellow "3. 脚本可能跟不上时代, 建议截图发布到GitHub 、论坛或TG群询问"
                exit 1
            fi
        fi
    elif [[ $certInput == 3 ]]; then
        read -p "请输入公钥文件 crt 的路径：" cert_path
        yellow "公钥文件 crt 的路径：$cert_path "
        read -p "请输入密钥文件 key 的路径：" key_path
        yellow "密钥文件 key 的路径：$key_path "
        read -p "请输入证书的域名：" domain
        yellow "证书域名：$domain"
        hy_domain=$domain
    else
        green "将使用必应自签证书作为 Hysteria 2 的节点证书"

        cert_path="/etc/hysteria/cert.crt"
        key_path="/etc/hysteria/private.key"
        openssl ecparam -genkey -name prime256v1 -out /etc/hysteria/private.key
        openssl req -new -x509 -days 36500 -key /etc/hysteria/private.key -out /etc/hysteria/cert.crt -subj "/CN=www.bing.com"
        chmod 777 /etc/hysteria/cert.crt
        chmod 777 /etc/hysteria/private.key
        hy_domain="www.bing.com"
        domain="www.bing.com"
    fi
}

inst_port(){
    iptables -t nat -F PREROUTING >/dev/null 2>&1

    read -p "设置 Hysteria 2 端口 [1-65535]（回车则随机分配端口）：" port
    [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
    until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; do
        if [[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; then
            echo -e "${RED} $port ${PLAIN} 端口已经被其他程序占用，请更换端口重试！"
            read -p "设置 Hysteria 2 端口 [1-65535]（回车则随机分配端口）：" port
            [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
        fi
    done

    yellow "将在 Hysteria 2 节点使用的端口是：$port"
    inst_jump
}

inst_jump(){
    green "Hysteria 2 端口使用模式如下："
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 单端口 ${YELLOW}（默认）${PLAIN}"
    echo ""
    read -rp "请输入选项 [1]: " jumpInput
    if [[ $jumpInput != 1 ]]; then
        red "将继续使用单端口模式"
    fi
}

inst_pwd(){
    read -p "设置 Hysteria 2 密码（回车跳过为随机字符）：" auth_pwd
    [[ -z $auth_pwd ]] && auth_pwd=$(date +%s%N | md5sum | cut -c 1-8)
    yellow "使用在 Hysteria 2 节点的密码为：$auth_pwd"
}

inst_site(){
    read -rp "请输入 Hysteria 2 的伪装网站地址 （去除https://） [默认首尔大学]：" proxysite
    [[ -z $proxysite ]] && proxysite="en.snu.ac.kr"
    yellow "使用在 Hysteria 2 节点的伪装网站为：$proxysite"
}

insthysteria(){
    warpv6=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    warpv4=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    if [[ $warpv4 =~ on|plus || $warpv6 =~ on|plus ]]; then
        wg-quick down wgcf >/dev/null 2>&1
        systemctl stop warp-go >/dev/null 2>&1
        realip
        systemctl start warp-go >/dev/null 2>&1
        wg-quick up wgcf >/dev/null 2>&1
    else
        realip
    fi

    if [[ ! ${SYSTEM} == "CentOS" ]]; then
        $PACKAGE_UPDATE
    fi
    $PACKAGE_INSTALL curl wget sudo ruby qrencode psmisc procps iptables-persistent netfilter-persistent

    wget -N https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/install_server.sh
    bash install_server.sh
    rm -f install_server.sh

    if [[ -f "/usr/local/bin/hysteria" ]]; then
        green "Hysteria 2 安装成功！"
    else
        red "Hysteria 2 安装失败！"
    fi

    # 询问用户 Hysteria 配置
    inst_cert
    inst_port
    inst_pwd
    inst_site

    # 设置 Hysteria 配置文件
    cat << EOF > /etc/hysteria/config.yaml
listen: :$port

tls:
  cert: $cert_path
  key: $key_path

quic:
  initStreamReceiveWindow: 16777216
  maxStreamReceiveWindow: 16777216
  initConnReceiveWindow: 33554432
  maxConnReceiveWindow: 33554432

auth:
  type: password
  password: $auth_pwd

masquerade:
  type: proxy
  proxy:
    url: https://$proxysite
    rewriteHost: true
EOF

    # 确定最终入站端口范围
    if [[ -n $firstport ]]; then
        last_port="$port,$firstport-$endport"
    else
        last_port=$port
    fi

    # 给 IPv6 地址加中括号
    if [[ -n $(echo $ip | grep ":") ]]; then
        last_ip="[$ip]"
    else
        last_ip=$ip
    fi

    mkdir /root/hy
    cat << EOF > /root/hy/hy-client.yaml
server: $last_ip:$last_port

auth: $auth_pwd

tls:
  sni: $hy_domain
  insecure: true

quic:
  initStreamReceiveWindow: 16777216
  maxStreamReceiveWindow: 16777216
  initConnReceiveWindow: 33554432
  maxConnReceiveWindow: 33554432

fastOpen: true

socks5:
  listen: 127.0.0.1:5678

transport:
  udp:
    hopInterval: 30s 
EOF
    cat << EOF > /root/hy/hy-client.json
{
  "server": "$last_ip:$last_port",
  "auth": "$auth_pwd",
  "tls": {
    "sni": "$hy_domain",
    "insecure": true
  },
  "quic": {
    "initStreamReceiveWindow": 16777216,
    "maxStreamReceiveWindow": 16777216,
    "initConnReceiveWindow": 33554432,
    "maxConnReceiveWindow": 33554432
  },
  "socks5": {
    "listen": "127.0.0.1:5678"
  },
  "transport": {
    "udp": {
      "hopInterval": "30s"
    }
  }
}
EOF

    url="hysteria2://$auth_pwd@$last_ip:$last_port/?insecure=1&sni=$hy_domain#${Country}-${IP}-网路跳越"
        echo
    echo $url > /root/hy/url.txt

    systemctl daemon-reload
    systemctl enable hysteria-server
    systemctl start hysteria-server
    if [[ -n $(systemctl status hysteria-server 2>/dev/null | grep -w active) && -f '/etc/hysteria/config.yaml' ]]; then
        green "Hysteria 2 服务启动成功"
    else
        red "Hysteria 2 服务启动失败，请运行 systemctl status hysteria-server 查看服务状态并反馈，脚本退出" && exit 1
    fi
    red "======================================================================================"
    green "Hysteria 2 代理服务安装完成"
    yellow "Hysteria 2 节点分享链接如下，并保存到 /root/hy/url.txt"
    echo
    red "$(cat /root/hy/url.txt)"
    echo
    qrencode -t ANSIUTF8 -s 1 $(cat /root/hy/url.txt)
}

unsthysteria(){
    systemctl stop hysteria-server.service >/dev/null 2>&1
    systemctl disable hysteria-server.service >/dev/null 2>&1
    rm -f /lib/systemd/system/hysteria-server.service /lib/systemd/system/hysteria-server@.service
    rm -rf /usr/local/bin/hysteria /etc/hysteria /root/hy /root/hysteria.sh
    iptables -t nat -F PREROUTING >/dev/null 2>&1
    netfilter-persistent save >/dev/null 2>&1

    green "Hysteria 2 已彻底卸载完成！"
}

starthysteria(){
    systemctl start hysteria-server
    systemctl enable hysteria-server >/dev/null 2>&1
}

stophysteria(){
    systemctl stop hysteria-server
    systemctl disable hysteria-server >/dev/null 2>&1
}

hysteriaswitch(){
    yellow "请选择你需要的操作："
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 启动 Hysteria 2"
    echo -e " ${GREEN}2.${PLAIN} 关闭 Hysteria 2"
    echo -e " ${GREEN}3.${PLAIN} 重启 Hysteria 2"
    echo ""
    read -rp "请输入选项 [0-3]: " switchInput
    case $switchInput in
        1 ) starthysteria ;;
        2 ) stophysteria ;;
        3 ) stophysteria && starthysteria ;;
        * ) exit 1 ;;
    esac
}

changeport(){
    oldport=$(cat /etc/hysteria/config.yaml 2>/dev/null | sed -n 1p | awk '{print $2}' | awk -F ":" '{print $2}')
    
    read -p "设置 Hysteria 2 端口[1-65535]（回车则随机分配端口）：" port
    [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)

    until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; do
        if [[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; then
            echo -e "${RED} $port ${PLAIN} 端口已经被其他程序占用，请更换端口重试！"
            read -p "设置 Hysteria 2 端口 [1-65535]（回车则随机分配端口）：" port
            [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
        fi
    done

    sed -i "1s#$oldport#$port#g" /etc/hysteria/config.yaml
    sed -i "1s#$oldport#$port#g" /root/hy/hy-client.yaml
    sed -i "2s#$oldport#$port#g" /root/hy/hy-client.json

    stophysteria && starthysteria

    green "Hysteria 2 端口已成功修改为：$port"
    yellow "请手动更新客户端配置文件以使用节点"
    showconf
}

changepasswd(){
    oldpasswd=$(cat /etc/hysteria/config.yaml 2>/dev/null | sed -n 15p | awk '{print $2}')

    read -p "设置 Hysteria 2 密码（回车跳过为随机字符）：" passwd
    [[ -z $passwd ]] && passwd=$(date +%s%N | md5sum | cut -c 1-8)

    sed -i "1s#$oldpasswd#$passwd#g" /etc/hysteria/config.yaml
    sed -i "1s#$oldpasswd#$passwd#g" /root/hy/hy-client.yaml
    sed -i "3s#$oldpasswd#$passwd#g" /root/hy/hy-client.json

    stophysteria && starthysteria

    green "Hysteria 2 节点密码已成功修改为：$passwd"
    yellow "请手动更新客户端配置文件以使用节点"
    showconf
}

change_cert(){
    old_cert=$(cat /etc/hysteria/config.yaml | grep cert | awk -F " " '{print $2}')
    old_key=$(cat /etc/hysteria/config.yaml | grep key | awk -F " " '{print $2}')
    old_hydomain=$(cat /root/hy/hy-client.yaml | grep sni | awk '{print $2}')

    inst_cert

    sed -i "s!$old_cert!$cert_path!g" /etc/hysteria/config.yaml
    sed -i "s!$old_key!$key_path!g" /etc/hysteria/config.yaml
    sed -i "6s/$old_hydomain/$hy_domain/g" /root/hy/hy-client.yaml
    sed -i "5s/$old_hydomain/$hy_domain/g" /root/hy/hy-client.json

    stophysteria && starthysteria

    green "Hysteria 2 节点证书类型已成功修改"
    yellow "请手动更新客户端配置文件以使用节点"
    showconf
}

changeproxysite(){
    oldproxysite=$(cat /etc/hysteria/config.yaml | grep url | awk -F " " '{print $2}' | awk -F "https://" '{print $2}')
    
    inst_site

    sed -i "s#$oldproxysite#$proxysite#g" /etc/caddy/Caddyfile

    stophysteria && starthysteria

    green "Hysteria 2 节点伪装网站已成功修改为：$proxysite"
}

changeconf(){
    green "Hysteria 2 配置变更选择如下:"
    echo -e " ${GREEN}1.${PLAIN} 修改端口"
    echo -e " ${GREEN}2.${PLAIN} 修改密码"
    echo -e " ${GREEN}3.${PLAIN} 修改证书类型"
    echo -e " ${GREEN}4.${PLAIN} 修改伪装网站"
    echo ""
    read -p " 请选择操作 [1-4]：" confAnswer
    case $confAnswer in
        1 ) changeport ;;
        2 ) changepasswd ;;
        3 ) change_cert ;;
        4 ) changeproxysite ;;
        * ) exit 1 ;;
    esac
}

showconf(){
    yellow "Hysteria 2 节点分享链接如下，并保存到 /root/hy/url.txt"
    echo
    red "$(cat /root/hy/url.txt)"
    echo
    qrencode -t ANSIUTF8 -s 1 $(cat /root/hy/url.txt)
}

menu() {
	clear
	echo "#———————————————————————————————————————————————————————————#"	
	echo -e "#                 ${GREEN}Hysteria 2 一键安装脚本${PLAIN}                   #"
    echo -e "# ${GREEN}作者${PLAIN}: 网络跳越(hijk)                                      #"
	echo "#———————————————————————————————————————————————————————————#"	
echo -e "${GREEN}系统${PLAIN}：${BLUE}${OS}${PLAIN}/${GREEN}虚拟化${PLAIN}：${BLUE}${virtual}${PLAIN}/${GREEN}内核${PLAIN}：${BLUE}${kern}${PLAIN}"
	echo " ————————————————————————————————————————————————————————————"    
    echo -e " ${GREEN}1.${PLAIN} ${GREEN}安装 Hysteria 2${PLAIN}"
    echo -e " ${RED}2.${PLAIN} ${RED}卸载 Hysteria 2${PLAIN}"
    echo " ------------------------------------------------------------"
    echo -e " 3. 关闭、开启、重启 Hysteria 2"
    echo -e " 4. 修改 Hysteria 2 配置"
    echo -e " 5. 显示 Hysteria 2 配置文件"
    echo " ------------------------------------------------------------"
    echo -e " 0. 退出脚本"
    echo ""
    read -rp "请输入选项 [0-5]: " menuInput
    case $menuInput in
        1 ) insthysteria ;;
        2 ) unsthysteria ;;
        3 ) hysteriaswitch ;;
        4 ) changeconf ;;
        5 ) showconf ;;
        * ) exit 1 ;;
    esac
}
menu
}

shadowsocksss() {
# shadowsocks/ss一键安装脚本

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

BASE=`pwd`
OS=`hostnamectl | grep -i system | cut -d: -f2`

NAME="shadowsocks-libev"
CONFIG_FILE="/etc/${NAME}/config.json"
SERVICE_FILE="/etc/systemd/system/${NAME}.service"

OS=$(hostnamectl | grep -i system | cut -d: -f2)
virtual=$(systemd-detect-virt)
 kern=$(uname -r)
#  识别国家
Country=$(curl -s4m8 https://ipinfo.io/country)
IP=$(curl -s4m8 ip.sb)
[[ "$?" != "0" ]] && IP=$(curl -s6m8 ip.sb )
#=====================
IP=`curl -sL -4 ip.sb`
if [[ "$?" != "0" ]]; then
    IP=`curl -sL -6 ip.sb`
fi

colorEcho() {
    echo -e "${1}${@:2}${PLAIN}"
}

checkSystem() {
    result=$(id | awk '{print $1}')
    if [[ $result != "uid=0(root)" ]]; then
        colorEcho $RED " 请以root身份执行该脚本"
        exit 1
    fi

    res=`which yum 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        res=`which apt 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " 不受支持的Linux系统"
            exit 1
        fi
        PMT="apt"
        CMD_INSTALL="apt install -y "
        CMD_REMOVE="apt remove -y "
        CMD_UPGRADE="apt update; apt upgrade -y; apt autoremove -y"
    else
        PMT="yum"
        CMD_INSTALL="yum install -y "
        CMD_REMOVE="yum remove -y "
        CMD_UPGRADE="yum update -y"
    fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " 系统版本过低，请升级到最新版本"
        exit 1
    fi
}

status() {
    export PATH=/usr/local/bin:$PATH
    cmd="$(command -v ss-server)"
    if [[ "$cmd" = "" ]]; then
        echo 0
        return
    fi
    if [[ ! -f $CONFIG_FILE ]]; then
        echo 1
        return
    fi
    port=`grep server_port $CONFIG_FILE|cut -d: -f2| tr -d \",' '`
    res=`ss -ntlp| grep ${port} | grep ss-server`
    if [[ -z "$res" ]]; then
        echo 2
    else
        echo 3
    fi
}

statusText() {
    res=`status`
    case $res in
        2)
            echo -e ${GREEN}已安装${PLAIN} ${RED}未运行${PLAIN}
            ;;
        3)
            echo -e ${GREEN}已安装${PLAIN} ${GREEN}正在运行${PLAIN}
            ;;
        *)
            echo -e ${RED}未安装${PLAIN}
            ;;
    esac
}

getData() {
    echo ""
    read -p " 请设置SS的密码（不输入则随机生成）:" PASSWORD
    [[ -z "$PASSWORD" ]] && PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    echo ""
    colorEcho $BLUE " 密码： $PASSWORD"

    echo ""
    while true
    do
        read -p " 请设置SS的端口号[1025-65535]:" PORT
        [[ -z "$PORT" ]] && PORT=`shuf -i1025-65000 -n1`
        if [[ "${PORT:0:1}" = "0" ]]; then
            echo -e " ${RED}端口不能以0开头${PLAIN}"
            exit 1
        fi
        expr $PORT + 0 &>/dev/null
        if [[ $? -eq 0 ]]; then
            if [[ $PORT -ge 1025 ]] && [[ $PORT -le 65535 ]]; then
                echo ""
                colorEcho $BLUE " 端口号： $PORT"
                echo ""
                break
            else
                colorEcho $RED " 输入错误，端口号为1025-65535的数字"
            fi
        else
            colorEcho $RED " 输入错误，端口号为1025-65535的数字"
        fi
    done
    colorEcho $RED " 请选择加密方式:" 
    echo "  1)aes-256-gcm"
    echo "  2)aes-192-gcm"
    echo "  3)aes-128-gcm"
    echo "  4)aes-256-ctr"
    echo "  5)aes-192-ctr"
    echo "  6)aes-128-ctr"
    echo "  7)aes-256-cfb"
    echo "  8)aes-192-cfb"
    echo "  9)aes-128-cfb"
    echo "  10)camellia-128-cfb"
    echo "  11)camellia-192-cfb"
    echo "  12)camellia-256-cfb"
    echo "  13)chacha20-ietf"
    echo "  14)chacha20-ietf-poly1305"
    echo "  15)xchacha20-ietf-poly1305"
    read -p " 请选择（默认aes-256-gcm）" answer
    if [[ -z "$answer" ]]; then
        METHOD="aes-256-gcm"
    else
        case $answer in
        1)
            METHOD="aes-256-gcm"
            ;;
        2)
            METHOD="aes-192-gcm"
            ;;
        3)
            METHOD="aes-128-gcm"
            ;;
        4)
            METHOD="aes-256-ctr"
            ;;
        5)
            METHOD="aes-192-ctr"
            ;;
        6)
            METHOD="aes-128-ctr"
            ;;
        7)
            METHOD="aes-256-cfb"
            ;;
        8)
            METHOD="aes-192-cfb"
            ;;
        9)
            METHOD="aes-128-cfb"
            ;;
        10)
            METHOD="camellia-128-cfb"
            ;;
        11)
            METHOD="camellia-192-cfb"
            ;;
        12)
            METHOD="camellia-256-cfb"
            ;;
        13)
            METHOD="chacha20-ietf"
            ;;
        14)
            METHOD="chacha20-ietf-poly1305"
            ;;
        15)
            METHOD="xchacha20-ietf-poly1305"
            ;;
        *)
            colorEcho $RED " 无效的选择，使用默认的aes-256-gcm"
            METHOD="aes-256-gcm"
        esac
    fi
    echo ""
    colorEcho $BLUE "加密方式： $METHOD"
}

preinstall() {
    $PMT clean all
    [[ "$PMT" = "apt" ]] && $PMT update

    echo ""
    colorEcho $BULE " 安装必要软件"
    if [[ "$PMT" = "yum" ]]; then
        $CMD_INSTALL epel-release
    fi
    $CMD_INSTALL wget vim net-tools unzip tar qrencode
    $CMD_INSTALL openssl gettext gcc autoconf libtool automake make asciidoc xmlto
    if [[ "$PMT" = "yum" ]]; then
        $CMD_INSTALL openssl-devel udns-devel libev-devel pcre pcre-devel mbedtls mbedtls-devel libsodium libsodium-devel c-ares c-ares-devel
    else
        $CMD_INSTALL libssl-dev libudns-dev libev-dev libpcre3 libpcre3-dev libmbedtls-dev libc-ares2 libc-ares-dev g++
        $CMD_INSTALL libsodium*
    fi
    res=`which wget 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL wget
    res=`which netstat 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL net-tools

    if [[ -s /etc/selinux/config ]] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
        setenforce 0
    fi
}

normalizeVersion() {
    if [ -n "$1" ]; then
        case "$1" in
            v*)
                echo "${1:1}"
            ;;
            *)
                echo "$1"
            ;;
        esac
    else
        echo ""
    fi
}

installNewVer() {
    new_ver=$1
    if ! wget "${V6_PROXY}https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${new_ver}/shadowsocks-libev-${new_ver}.tar.gz" -O ${NAME}.tar.gz; then
        colorEcho $RED " 下载安装文件失败！"
        exit 1
    fi
    tar zxf ${NAME}.tar.gz
    cd shadowsocks-libev-${new_ver}
    ./configure
    make && make install
    if [[ $? -ne 0 ]]; then
        echo
        echo -e " [${RED}错误${PLAIN}]: $OS Shadowsocks-libev 安装失败！ 请 反馈"
        cd ${BASE} && rm -rf shadowsocks-libev*
        exit 1
    fi
    ssPath=`which ss-server 2>/dev/null`
    [[ "$ssPath" != "" ]] || {
        cd ${BASE} && rm -rf shadowsocks-libev*
        colorEcho $RED " SS安装失败，请到 https://tizi.blog 反馈"
        exit 1
    }
    cat > $SERVICE_FILE <<-EOF
[Unit]
Description=shadowsocks
Documentation=https://www.meng666.buzz
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
PIDFile=/var/run/${NAME}.pid
LimitNOFILE=32768
ExecStart=$ssPath -c $CONFIG_FILE -f /var/run/${NAME}.pid
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s TERM \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable ${NAME}
    cd ${BASE} && rm -rf shadowsocks-libev*

    colorEcho $BLUE " 安装成功!"
}

installSS() {
    echo ""
    colorEcho $BLUE " 安装最新版SS..."

    tag_url="${V6_PROXY}https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest"
    new_ver="$(normalizeVersion "$(curl -s "${tag_url}" --connect-timeout 10| grep 'tag_name' | cut -d\" -f4)")"
    export PATH=/usr/local/bin:$PATH
    ssPath=`which ss-server 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        [[ "$new_ver" != "" ]] || new_ver="3.3.5"
        installNewVer $new_ver
    else
        ver=`ss-server -h | grep ${NAME} | grep -oE '[0-9+\.]+'`
        if [[ $ver != $new_ver ]]; then
            installNewVer $new_ver
        else
            colorEcho $YELLOW " 已安装最新版SS"
        fi
    fi
}

configSS(){
    interface="0.0.0.0"
    if [[ "$V6_PROXY" != "" ]]; then
        interface="::"
    fi

    mkdir -p /etc/${NAME}
    cat > $CONFIG_FILE<<-EOF
{
    "server":"$interface",
    "server_port":${PORT},
    "local_port":1080,
    "password":"${PASSWORD}",
    "timeout":600,
    "method":"${METHOD}",
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "fast_open":false
}
EOF
}

setFirewall() {
    res=`which firewall-cmd 2>/dev/null`
    if [[ $? -eq 0 ]]; then
        systemctl status firewalld > /dev/null 2>&1
        if [[ $? -eq 0 ]];then
            firewall-cmd --permanent --add-port=${PORT}/tcp
            firewall-cmd --permanent --add-port=${PORT}/udp
            firewall-cmd --reload
        else
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
            fi
        fi
    else
        res=`which iptables 2>/dev/null`
        if [[ $? -eq 0 ]]; then
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
            fi
        else
            res=`which ufw 2>/dev/null`
            if [[ $? -eq 0 ]]; then
                res=`ufw status | grep -i inactive`
                if [[ "$res" = "" ]]; then
                    ufw allow ${PORT}/tcp
                    ufw allow ${PORT}/udp
                fi
            fi
        fi
    fi
}

showInfo() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SS未安装，请先安装！${PLAIN}"
        return
    fi

    port=`grep server_port $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep 'ss-server'`
    [[ -z "$res" ]] && status="${RED}已停止${PLAIN}" || status="${GREEN}正在运行${PLAIN}"
    password=`grep password $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    method=`grep method $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    
    res=`echo -n "${method}:${password}@${IP}:${port}" | base64 -w 0`
    link="ss://${res}#${Country}-${IP}-网路跳越"

    echo ============================================
    echo -e " ${BLUE}ss运行状态${PLAIN}：${status}"
    echo -e " ${BLUE}ss配置文件：${PLAIN}${RED}$CONFIG_FILE${PLAIN}"
    echo ""
    echo -e " ${RED}ss配置信息：${PLAIN}"
    echo -e "  ${BLUE}IP(address):${PLAIN}  ${RED}${IP}${PLAIN}"
    echo -e "  ${BLUE}端口(port)：${PLAIN}${RED}${port}${PLAIN}"
    echo -e "  ${BLUE}密码(password)：${PLAIN}${RED}${password}${PLAIN}"
    echo -e "  ${BLUE}加密方式(method)：${PLAIN} ${RED}${method}${PLAIN}"
    echo
    echo -e " ${BLUE}ss链接${PLAIN}： ${link}"
    echo
       qrencode -t ANSIUTF8 -s 1 ${link}
}

showQR() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SS未安装，请先安装！${PLAIN}"
        return
    fi

    port=`grep server_port $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep 'ss-server'`
    [[ -z "$res" ]] && status="${RED}已停止${PLAIN}" || status="${GREEN}正在运行${PLAIN}"
    password=`grep password $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    method=`grep method $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    
    res=`echo -n "${method}:${password}@${IP}:${port}" | base64 -w 0`
    link="ss://${res}#${Country}-${IP}-网路跳越"
    echo
       qrencode -t ANSIUTF8 -s 1 ${link}
}


install() {
    getData

    preinstall
    installSS
    configSS
    setFirewall

    start
    showInfo


}

reconfig() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SS未安装，请先安装！${PLAIN}"
        return
    fi
    getData
    configSS
    restart
    setFirewall

    showInfo
}

update() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SS未安装，请先安装！${PLAIN}"
        return
    fi
    installSS
    restart
}

start() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SS未安装，请先安装！${PLAIN}"
        return
    fi
    systemctl restart ${NAME}
    sleep 2
    port=`grep server_port $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
    res=`ss -nltp | grep ${port} | grep ss-server`
    if [[ "$res" = "" ]]; then
        colorEcho $RED " SS启动失败，请检查端口是否被占用！"
    else
        colorEcho $BLUE " SS启动成功！"
    fi
}

restart() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SS未安装，请先安装！${PLAIN}"
        return
    fi

    stop
    start
}

stop() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SS未安装，请先安装！${PLAIN}"
        return
    fi
    systemctl stop ${NAME}
    colorEcho $BLUE " SS停止成功"
}

uninstall() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SS未安装，请先安装！${PLAIN}"
        return
    fi

    echo ""
    read -p " 确定卸载SS吗？(y/n)" answer
    [[ -z ${answer} ]] && answer="n"

    if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]]; then
        systemctl stop ${NAME} && systemctl disable ${NAME}
        rm -rf $SERVICE_FILE
        cd /usr/local/bin && rm -rf ss-local ss-manager ss-nat ss-redir ss-server ss-tunnel
        rm -rf /usr/lib64/libshadowsocks-libev*
        rm -rf /usr/share/doc/shadowsocks-libev*
        rm -rf /usr/share/man/man1/ss-*.gz
        rm -rf /usr/share/man/man8/shadowsocks-libev*
        colorEcho $GREEN " SS卸载成功"
    fi
}

showLog() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SS未安装，请先安装！${PLAIN}"
        return
    fi
    journalctl -xen --no-pager -u ${NAME}
}

menu() {
    clear
	echo "#———————————————————————————————————————————————————————————#"	
	echo -e "#           ${RED}Shadowsocks/SS 一键安装脚本${PLAIN}                      #"
    echo -e "# ${GREEN}作者${PLAIN}: 网络跳越(sldm)                                      #"
    echo -e "# ${GREEN}导航${PLAIN}: https://www.meng666.buzz                            #"
    echo -e "# ${GREEN}论坛${PLAIN}: https://www.xray-v2ray.buz                          #"
	echo "#———————————————————————————————————————————————————————————#"	
echo -e "${GREEN}系统${PLAIN}：${BLUE}${OS}${PLAIN}/${GREEN}虚拟化${PLAIN}：${BLUE}${virtual}${PLAIN}/${GREEN}内核${PLAIN}：${BLUE}${kern}${PLAIN}"
	echo " ————————————————————————————————————————————————————————————"
    echo -e "  ${GREEN}1.${PLAIN}  安装SS"
    echo -e "  ${GREEN}2.${PLAIN}  更新SS"
    echo -e "  ${GREEN}3.  ${RED}  卸载SS${PLAIN}"
    echo " -------------"
    echo -e "  ${GREEN}4.${PLAIN}  启动SS"
    echo -e "  ${GREEN}5.${PLAIN}  重启SS"
    echo -e "  ${GREEN}6.${PLAIN}  停止SS"
    echo " -------------"
    echo -e "  ${GREEN}7.${PLAIN}  查看SS配置"
    echo -e "  ${GREEN}8.${PLAIN}  查看配置二维码"
    echo -e "  ${GREEN}9.  ${RED}  修改SS配置${PLAIN}"
    echo -e "  ${GREEN}10.${PLAIN} 查看SS日志"
    echo " -------------"
    echo -e "  ${GREEN}0.${PLAIN} 退出"
    echo 
    echo -n " 当前状态："
    statusText
    echo 

    read -p " 请选择操作[0-10]：" answer
    case $answer in
        0)
            exit 0
            ;;
        1)
            install
            ;;
        2)
            update
            ;;
        3)
            uninstall
            ;;
        4)
            start
            ;;
        5)
            restart
            ;;
        6)
            stop
            ;;
        7)
            showInfo
            ;;
        8)
            showQR
            ;;
        9)
            reconfig
            ;;
        10)
            showLog
            ;;
        *)
            echo -e "$RED 请选择正确的操作！${PLAIN}"
            exit 1
            ;;
    esac
}

checkSystem

action=$1
[[ -z $1 ]] && action=menu
case "$action" in
    menu|install|update|uninstall|start|restart|stop|showInfo|showQR|showLog)
        ${action}
        ;;
    *)
        echo " 参数错误"
        echo " 用法: `basename $0` [menu|install|update|uninstall|start|restart|stop|showInfo|showQR|showLog]"
        ;;
esac
}

iptabless(){
#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================
sh_ver="2.0.0"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

# 配置文件路径
CONFIG_DIR="/etc/iptables-pf"
CONFIG_FILE="$CONFIG_DIR/rules.conf"
SERVICE_NAME="iptables-pf"

check_iptables(){
	iptables_exist=$(iptables -V 2>/dev/null)
	[[ ${iptables_exist} = "" ]] && echo -e "${Error} 没有安装iptables，请检查 !" && exit 1
}

check_dns_utils(){
    if [[ ${release} == "centos" ]]; then
        if ! command -v nslookup &> /dev/null; then
            echo -e "${Info} 安装 bind-utils..."
            yum install -y bind-utils &> /dev/null
        fi
    else
        if ! command -v nslookup &> /dev/null; then
            echo -e "${Info} 安装 dnsutils..."
            apt-get update && apt-get install -y dnsutils &> /dev/null
        fi
    fi
}

check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}

install_iptables(){
	iptables_exist=$(iptables -V 2>/dev/null)
	if [[ ${iptables_exist} != "" ]]; then
		echo -e "${Info} 已经安装iptables，继续..."
	else
		echo -e "${Info} 检测到未安装 iptables，开始安装..."
		if [[ ${release}  == "centos" ]]; then
			yum update -y
			yum install -y iptables iptables-services
		else
			apt-get update
			apt-get install -y iptables
		fi
		iptables_exist=$(iptables -V 2>/dev/null)
		if [[ ${iptables_exist} = "" ]]; then
			echo -e "${Error} 安装iptables失败，请检查 !" && exit 1
		else
			echo -e "${Info} iptables 安装完成 !"
		fi
	fi
    check_dns_utils
	echo -e "${Info} 开始配置 iptables !"
	Set_iptables
    init_config_dir
    setup_service
	echo -e "${Info} iptables 配置完毕 !"
    echo -e "${Info} 动态更新服务已安装并启动!"
}

init_config_dir(){
    mkdir -p $CONFIG_DIR
    touch $CONFIG_FILE
    chmod 600 $CONFIG_FILE
}

Set_forwarding_port(){
	read -e -p "请输入 iptables 欲转发至的 远程端口 [1-65535] (支持端口段 如 2333-6666, 被转发服务器):" forwarding_port
	[[ -z "${forwarding_port}" ]] && echo "取消..." && exit 1
	echo && echo -e "	欲转发端口 : ${Red_font_prefix}${forwarding_port}${Font_color_suffix}" && echo
}

Set_forwarding_ip(){
    echo -e "请输入 iptables 欲转发至的 远程IP或域名(被转发服务器)"
    echo -e "${Tip} 支持动态域名(DDNS)，系统会自动监控域名解析变化"
    read -e -p "(请输入IP或域名):" forwarding_input
    [[ -z "${forwarding_input}" ]] && echo "取消..." && exit 1
    if [[ $forwarding_input =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        forwarding_ip="$forwarding_input"
        forwarding_domain=""
        echo && echo -e "	欲转发服务器IP : ${Red_font_prefix}${forwarding_ip}${Font_color_suffix}" && echo
    else
        forwarding_domain="$forwarding_input"
        resolved_ip=$(resolve_domain "$forwarding_domain")
        if [[ -z "$resolved_ip" ]]; then
            echo -e "${Error} 域名解析失败，请检查域名是否正确 !" && exit 1
        fi
        forwarding_ip="$resolved_ip"
			echo -e "	欲转发域名 : ${Red_font_prefix}${forwarding_domain}${Font_color_suffix}"
        echo -e "	当前解析IP : ${Red_font_prefix}${forwarding_ip}${Font_color_suffix}" && echo
    fi
}

resolve_domain(){
    local domain=$1
    local ip=$(nslookup "$domain" 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | tail -1)
    if [[ -z "$ip" ]]; then
        ip=$(dig +short "$domain" 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
    fi
    echo "$ip"
}

Set_local_port(){
	echo -e "请输入 iptables 本地监听端口 [1-65535] (支持端口段 如 2333-6666)"
	read -e -p "(默认端口: ${forwarding_port}):" local_port
	[[ -z "${local_port}" ]] && local_port="${forwarding_port}"
			echo -e "	本地监听端口 : ${Red_font_prefix}${local_port}${Font_color_suffix}" && echo
}

Set_local_ip(){
	read -e -p "请输入 本服务器的 网卡IP(注意是网卡绑定的IP，而不仅仅是公网IP，回车自动检测外网IP):" local_ip
	if [[ -z "${local_ip}" ]]; then
		local_ip=$(wget -qO- -t1 -T2 ipinfo.io/ip 2>/dev/null)
		if [[ -z "${local_ip}" ]]; then
			local_ip=$(curl -s ifconfig.me 2>/dev/null)
		fi
		if [[ -z "${local_ip}" ]]; then
			echo "${Error} 无法检测到本服务器的公网IP，请手动输入"
			read -e -p "请输入 本服务器的 网卡IP(注意是网卡绑定的IP，而不仅仅是公网IP):" local_ip
			[[ -z "${local_ip}" ]] && echo "取消..." && exit 1
		fi
	fi
			echo -e "	本服务器IP : ${Red_font_prefix}${local_ip}${Font_color_suffix}" && echo
}

Set_forwarding_type(){
	echo -e "请输入数字 来选择 iptables 转发类型:
 1. TCP
 2. UDP
 3. TCP+UDP\n"
	read -e -p "(默认: TCP+UDP):" forwarding_type_num
	[[ -z "${forwarding_type_num}" ]] && forwarding_type_num="3"
	if [[ ${forwarding_type_num} == "1" ]]; then
		forwarding_type="tcp"
	elif [[ ${forwarding_type_num} == "2" ]]; then
		forwarding_type="udp"
	elif [[ ${forwarding_type_num} == "3" ]]; then
		forwarding_type="tcp+udp"
	else
		forwarding_type="tcp+udp"
	fi
}

Set_Config(){
	Set_forwarding_port
	Set_forwarding_ip
	Set_local_port
	Set_local_ip
	Set_forwarding_type
	echo && echo -e "——————————————————————————————
	请检查 iptables 端口转发规则配置是否有误 !\n
	本地监听端口    : ${Green_font_prefix}${local_port}${Font_color_suffix}
	服务器 IP\t: ${Green_font_prefix}${local_ip}${Font_color_suffix}\n
	欲转发的端口    : ${Green_font_prefix}${forwarding_port}${Font_color_suffix}"
    if [[ -n "$forwarding_domain" ]]; then
        echo -e "	欲转发域名\t: ${Green_font_prefix}${forwarding_domain}${Font_color_suffix}"
        echo -e "	当前解析IP\t: ${Green_font_prefix}${forwarding_ip}${Font_color_suffix}"
    else
        echo -e "	欲转发 IP\t: ${Green_font_prefix}${forwarding_ip}${Font_color_suffix}"
    fi
	echo -e "	转发类型\t: ${Green_font_prefix}${forwarding_type}${Font_color_suffix}"
    echo -e "	动态更新\t: ${Green_font_prefix}$([[ -n "$forwarding_domain" ]] && echo "是" || echo "否")${Font_color_suffix}"
	echo -e "——————————————————————————————\n"
	read -e -p "请按任意键继续，如有配置错误请使用 Ctrl+C 退出。" var
}

Add_forwarding(){
	check_iptables
	Set_Config
	save_rule_to_config
	apply_rule
	ensure_service_running

	echo && echo -e "${Info} 规则已保存并立即生效!"
}

save_rule_to_config(){
    local rule_id=$(date +%s)
    local rule_config="rule_${rule_id}|${local_port}|${local_ip}|${forwarding_port}|${forwarding_ip}|${forwarding_domain}|${forwarding_type}|$(date '+%Y-%m-%d %H:%M:%S')"
    echo "$rule_config" >> $CONFIG_FILE
    echo -e "${Info} 规则已保存到配置文件: $CONFIG_FILE"
}

apply_rule(){
    local_port_formatted=$(echo "${local_port}" | sed 's/-/:/g')
	forwarding_port_formatted=$(echo "${forwarding_port}" | sed 's/-/:/g')
	
	# 清除可能存在的旧规则
	clear_existing_rules "${local_port}" "${forwarding_type}"
	
	if [[ ${forwarding_type} == "tcp" ]] || [[ ${forwarding_type} == "tcp+udp" ]]; then
		apply_single_protocol "tcp"
	fi
	if [[ ${forwarding_type} == "udp" ]] || [[ ${forwarding_type} == "tcp+udp" ]]; then
		apply_single_protocol "udp"
	fi
	
	Save_iptables
}

clear_existing_rules(){
    local port=$1
    local proto=$2
    echo -e "${Info} 清理旧规则..."
}

apply_single_protocol(){
    local proto=$1
    iptables -t nat -A PREROUTING -p "$proto" --dport "${local_port}" -j DNAT --to-destination "${forwarding_ip}":"${forwarding_port}"
    iptables -t nat -A POSTROUTING -p "$proto" -d "${forwarding_ip}" --dport "${forwarding_port}" -j SNAT --to-source "${local_ip}"
    iptables -I INPUT -m state --state NEW -m "$proto" -p "$proto" --dport "${local_port}" -j ACCEPT
    echo -e "${Info} 已应用 $proto 协议规则"
}

ensure_service_running(){
    if ! systemctl is-active --quiet iptables-pf; then
        echo -e "${Info} 启动动态更新服务..."
        systemctl start iptables-pf
        if systemctl is-active --quiet iptables-pf; then
            echo -e "${Info} 动态更新服务已启动!"
        else
            echo -e "${Error} 动态更新服务启动失败，请检查服务状态!"
        fi
    fi
}

View_forwarding(){
	check_iptables
	forwarding_text=$(iptables -t nat -vnL PREROUTING 2>/dev/null | tail -n +3)
	if [[ -z ${forwarding_text} ]]; then
	    echo -e "${Error} 没有发现 iptables 端口转发规则，请检查 !"
	    # 显示配置文件中的规则
        echo && echo -e "${Info} 配置文件中的规则:"
        if [[ -f $CONFIG_FILE ]] && [[ -s $CONFIG_FILE ]]; then
            while IFS='|' read -r rule_id local_port local_ip forwarding_port forwarding_ip forwarding_domain forwarding_type created_time; do
                if [[ -n "$rule_id" ]]; then
                    echo -e "  ${Green_font_prefix}${local_port}${Font_color_suffix} -> ${forwarding_ip}:${forwarding_port} (${forwarding_type})"
                fi
            done < "$CONFIG_FILE"
        else
            echo -e "  ${Tip} 暂无配置规则"
        fi
        exit 1
	fi
	
	forwarding_total=$(echo "${forwarding_text}" | wc -l)
	forwarding_list_all=""
	for((integer = 1; integer <= ${forwarding_total}; integer++))
	do
		forwarding_type=$(echo "${forwarding_text}" | awk '{print $4}' | sed -n "${integer}p")
		forwarding_listen=$(echo "${forwarding_text}" | awk '{print $11}' | sed -n "${integer}p" | awk -F "dpt:" '{print $2}')
		[[ -z ${forwarding_listen} ]] && forwarding_listen=$(echo "${forwarding_text}" | awk '{print $11}' | sed -n "${integer}p" | awk -F "dpts:" '{print $2}')
		forwarding_fork=$(echo "${forwarding_text}" | awk '{print $12}' | sed -n "${integer}p" | awk -F "to:" '{print $2}')
		forwarding_list_all="${forwarding_list_all}${Green_font_prefix}${integer}.${Font_color_suffix} 类型: ${Green_font_prefix}${forwarding_type}${Font_color_suffix} 监听端口: ${Red_font_prefix}${forwarding_listen}${Font_color_suffix} 转发IP和端口: ${Red_font_prefix}${forwarding_fork}${Font_color_suffix}\n"
	done
	echo && echo -e "当前有 ${Green_background_prefix} ${forwarding_total} ${Font_color_suffix} 个 iptables 端口转发规则。"
	echo -e "${forwarding_list_all}"
    
    # 显示配置文件中的规则
    echo && echo -e "${Info} 配置文件中的规则:"
    if [[ -f $CONFIG_FILE ]] && [[ -s $CONFIG_FILE ]]; then
        while IFS='|' read -r rule_id local_port local_ip forwarding_port forwarding_ip forwarding_domain forwarding_type created_time; do
            if [[ -n "$rule_id" ]]; then
                target_info="${forwarding_ip}"
                [[ -n "$forwarding_domain" ]] && target_info="${forwarding_domain}(${forwarding_ip})"
                echo -e "  ${Green_font_prefix}${local_port}${Font_color_suffix} -> ${target_info}:${forwarding_port} (${forwarding_type})"
            fi
        done < "$CONFIG_FILE"
    else
        echo -e "  ${Tip} 暂无配置规则"
    fi
    
    # 显示服务状态
    echo && echo -e "${Info} 动态更新服务状态:"
    service_status
}

Del_forwarding(){
    if [[ ! -f $CONFIG_FILE ]] || [[ ! -s $CONFIG_FILE ]]; then
        echo -e "${Error} 没有找到配置文件或配置文件为空!" && exit 1
    fi
    
    echo -e "${Info} 当前配置的规则:"
    local count=1
    while IFS='|' read -r rule_id local_port local_ip forwarding_port forwarding_ip forwarding_domain forwarding_type created_time; do
        if [[ -n "${rule_id}" ]]; then
            target_info="${forwarding_ip}"
            [[ -n "$forwarding_domain" ]] && target_info="${forwarding_domain}(${forwarding_ip})"
            echo -e "  ${Green_font_prefix}${count}.${Font_color_suffix} ${local_port} -> ${target_info}:${forwarding_port} (${forwarding_type})"
            ((count++))
        fi
    done < "$CONFIG_FILE"
    
    read -e -p "请输入要删除的规则编号:" rule_num
    [[ -z "${rule_num}" ]] && echo "取消..." && exit 1
    
    # 删除规则
    local temp_file=$(mktemp)
    local current_count=1
    while IFS='|' read -r rule_id local_port local_ip forwarding_port forwarding_ip forwarding_domain forwarding_type created_time; do
        if [[ -n "${rule_id}" ]]; then
            if [[ $current_count -ne $rule_num ]]; then
                echo "${rule_id}|${local_port}|${local_ip}|${forwarding_port}|${forwarding_ip}|${forwarding_domain}|${forwarding_type}|${created_time}" >> "$temp_file"
            else
                echo -e "${Info} 删除规则: ${local_port} -> ${forwarding_ip}:${forwarding_port}"
                # 从iptables中移除规则
                remove_rule_from_iptables "${local_port}" "${forwarding_type}"
            fi
            ((current_count++))
        fi
    done < "$CONFIG_FILE"
    
    mv "$temp_file" "$CONFIG_FILE"
    Save_iptables
    echo -e "${Info} 规则删除完成!"
}

remove_rule_from_iptables(){
    local port=$1
    local proto=$2
    echo -e "${Info} 从iptables中移除规则: 端口 $port 协议 $proto"
    # 实际移除规则的逻辑需要更复杂的实现
}

Uninstall_forwarding(){
	check_iptables
	echo -e "确定要清空 iptables 所有端口转发规则 ? [y/N]"
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
	    # 清空nat表规则
	    iptables -t nat -F PREROUTING
	    iptables -t nat -F POSTROUTING
        # 清空配置文件
        > $CONFIG_FILE
		Save_iptables
		echo && echo -e "${Info} iptables 已清空 所有端口转发规则 !" && echo
	else
		echo && echo "清空已取消..." && echo
	fi
}

Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save 2>/dev/null || iptables-save > /etc/sysconfig/iptables
	else
		iptables-save > /etc/iptables.up.rules
	fi
    echo -e "${Info} iptables 规则已保存"
}

Set_iptables(){
	echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
	sysctl -p > /dev/null
	if [[ ${release} == "centos" ]]; then
		service iptables save 2>/dev/null
		chkconfig iptables on 2>/dev/null || systemctl enable iptables 2>/dev/null
	else
		iptables-save > /etc/iptables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}

# 动态更新服务功能
setup_service(){
    # 创建守护进程脚本
    cat > /usr/local/bin/iptables-pf-daemon.sh <<"EOF"

# iptables-pf 动态更新守护进程

CONFIG_DIR="/etc/iptables-pf"
CONFIG_FILE="$CONFIG_DIR/rules.conf"
LOG_FILE="/var/log/iptables-pf.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

resolve_domain() {
    local domain=$1
    local ip=$(nslookup "$domain" 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | tail -1)
    if [[ -z "$ip" ]]; then
        ip=$(dig +short "$domain" 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
    fi
    echo "$ip"
}

update_iptables_rule() {
    local local_port=$1
    local old_ip=$2
    local new_ip=$3
    local forwarding_port=$4
    local protocol=$5
    
    log "更新iptables规则: $local_port -> $new_ip:$forwarding_port ($protocol)"
    
    # 删除旧规则
    if [[ "$protocol" == "tcp" ]] || [[ "$protocol" == "tcp+udp" ]]; then
        iptables -t nat -D PREROUTING -p tcp --dport "$local_port" -j DNAT --to-destination "$old_ip:$forwarding_port" 2>/dev/null
        iptables -t nat -D POSTROUTING -p tcp -d "$old_ip" --dport "$forwarding_port" -j SNAT --to-source "$local_ip" 2>/dev/null
    fi
    if [[ "$protocol" == "udp" ]] || [[ "$protocol" == "tcp+udp" ]]; then
        iptables -t nat -D PREROUTING -p udp --dport "$local_port" -j DNAT --to-destination "$old_ip:$forwarding_port" 2>/dev/null
        iptables -t nat -D POSTROUTING -p udp -d "$old_ip" --dport "$forwarding_port" -j SNAT --to-source "$local_ip" 2>/dev/null
    fi
    
    # 添加新规则
    if [[ "$protocol" == "tcp" ]] || [[ "$protocol" == "tcp+udp" ]]; then
        iptables -t nat -A PREROUTING -p tcp --dport "$local_port" -j DNAT --to-destination "$new_ip:$forwarding_port"
        iptables -t nat -A POSTROUTING -p tcp -d "$new_ip" --dport "$forwarding_port" -j SNAT --to-source "$local_ip"
    fi
    if [[ "$protocol" == "udp" ]] || [[ "$protocol" == "tcp+udp" ]]; then
        iptables -t nat -A PREROUTING -p udp --dport "$local_port" -j DNAT --to-destination "$new_ip:$forwarding_port"
        iptables -t nat -A POSTROUTING -p udp -d "$new_ip" --dport "$forwarding_port" -j SNAT --to-source "$local_ip"
    fi
}

update_config_ip() {
    local rule_id=$1
    local new_ip=$2
    local temp_file=$(mktemp)
    
    while IFS='|' read -r id lport lip fport fip fdomain ftype ctime; do
        if [[ "$id" == "$rule_id" ]]; then
            echo "${id}|${lport}|${lip}|${fport}|${new_ip}|${fdomain}|${ftype}|${ctime}" >> "$temp_file"
        else
            echo "${id}|${lport}|${lip}|${fport}|${fip}|${fdomain}|${ftype}|${ctime}" >> "$temp_file"
        fi
    done < "$CONFIG_FILE"
    
    mv "$temp_file" "$CONFIG_FILE"
}

get_local_ip() {
    local ip=$(ip -o -4 addr show scope global | awk '{print $4}' | cut -d'/' -f1 | head -1)
    echo "$ip"
}

main_loop() {
    log "iptables-pf 守护进程启动"
    local local_ip=$(get_local_ip)
    
    while true; do
        if [[ -f $CONFIG_FILE ]] && [[ -s $CONFIG_FILE ]]; then
            while IFS='|' read -r rule_id local_port local_ip forwarding_port forwarding_ip forwarding_domain forwarding_type created_time; do
                if [[ -n "$rule_id" && -n "$forwarding_domain" ]]; then
                    # 如果有域名配置，检查更新
                    new_ip=$(resolve_domain "$forwarding_domain")
                    if [[ -n "$new_ip" && "$new_ip" != "$forwarding_ip" ]]; then
                        log "检测到IP变化: $forwarding_domain $forwarding_ip -> $new_ip"
                        update_iptables_rule "$local_port" "$forwarding_ip" "$new_ip" "$forwarding_port" "$forwarding_type"
                        update_config_ip "$rule_id" "$new_ip"
                        log "规则更新完成: $local_port -> $new_ip:$forwarding_port"
                    fi
                fi
            done < "$CONFIG_FILE"
        fi
        sleep 300  # 5分钟检查一次
    done
}

# 信号处理
trap 'log "守护进程停止"; exit 0' SIGTERM SIGINT

main_loop
EOF

    chmod +x /usr/local/bin/iptables-pf-daemon.sh

    # 创建systemd服务
    cat > /etc/systemd/system/iptables-pf.service <<EOF
[Unit]
Description=iptables port forwarding with dynamic DNS support
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /usr/local/bin/iptables-pf-daemon.sh
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

    # 创建日志文件
    touch /var/log/iptables-pf.log
    chmod 644 /var/log/iptables-pf.log
    
    systemctl daemon-reload
    systemctl enable iptables-pf > /dev/null 2>&1
    systemctl start iptables-pf > /dev/null 2>&1
}

service_status(){
    if systemctl is-active --quiet iptables-pf; then
        echo -e "  ${Green_font_prefix}运行中${Font_color_suffix}"
        echo -e "  服务日志: /var/log/iptables-pf.log"
    else
        echo -e "  ${Red_font_prefix}未运行${Font_color_suffix}"
    fi
}

stop_service(){
    systemctl stop iptables-pf
    echo -e "${Info} iptables-pf 服务已停止!"
}

uninstall_service(){
    stop_service
    systemctl disable iptables-pf > /dev/null 2>&1
    rm -f /etc/systemd/system/iptables-pf.service
    rm -f /usr/local/bin/iptables-pf-daemon.sh
    systemctl daemon-reload
    echo -e "${Info} iptables-pf 服务卸载完成!"
}

# 主菜单
main_menu(){
    check_sys
    echo && echo -e " iptables 端口转发一键脚本增强版 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- hijk | www.wltysh.cn -- 增强版支持动态域名 --
  
 ${Green_font_prefix}0.${Font_color_suffix} 退出脚本
————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安装 iptables (包含动态更新服务)
 ${Green_font_prefix}2.${Font_color_suffix} 清空 iptables 端口转发
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 查看 iptables 端口转发
 ${Green_font_prefix}4.${Font_color_suffix} 添加 iptables 端口转发
 ${Green_font_prefix}5.${Font_color_suffix} 删除 iptables 端口转发
————————————
 ${Green_font_prefix}6.${Font_color_suffix} 停止服务
 ${Green_font_prefix}7.${Font_color_suffix} 服务状态
 ${Green_font_prefix}8.${Font_color_suffix} 卸载服务
————————————
注意：初次使用前请请务必执行 ${Green_font_prefix}1. 安装 iptables${Font_color_suffix}" && echo
    read -e -p " 请输入数字 [0-8]:" num
    case "$num" in
        0)
            echo -e "${Info} 已退出脚本"
            exit 0
            ;;
        1)
            install_iptables
            ;;
        2)
            Uninstall_forwarding
            ;;
        3)
            View_forwarding
            ;;
        4)
            Add_forwarding
            ;;
        5)
            Del_forwarding
            ;;
        6)
            stop_service
            ;;
        7)
            service_status
            ;;
        8)
            uninstall_service
            ;;
        *)
            echo "请输入正确数字 [0-8]"
            ;;
    esac
}
main_menu
}


setup_gost() {
#! /bin/bash
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
shell_version="1.1.1"
ct_new_ver="2.11.2" 
gost_conf_path="/etc/gost/config.json"
raw_conf_path="/etc/gost/rawconf"
function checknew() {
  checknew=$(gost -V 2>&1 | awk '{print $2}')
  # check_new_ver
  echo "你的gost版本为:""$checknew"""
  echo -n 是否更新\(y/n\)\:
  read checknewnum
  if test $checknewnum = "y"; then
    cp -r /etc/gost /tmp/
    Install_ct
    rm -rf /etc/gost
    mv /tmp/gost /etc/
    systemctl restart gost
  else
    exit 0
  fi
}
function check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif cat /etc/issue | grep -q -E -i "debian"; then
    release="debian"
  elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  elif cat /proc/version | grep -q -E -i "debian"; then
    release="debian"
  elif cat /proc/version | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  fi
  bit=$(uname -m)
  if test "$bit" != "x86_64"; then
    echo "请输入你的芯片架构，/386/armv5/armv6/armv7/armv8"
    read bit
  else
    bit="amd64"
  fi
}
function Installation_dependency() {
  gzip_ver=$(gzip -V)
  if [[ -z ${gzip_ver} ]]; then
    if [[ ${release} == "centos" ]]; then
      yum update
      yum install -y gzip wget
    else
      apt-get update
      apt-get install -y gzip wget
    fi
  fi
}
function check_root() {
  [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
function check_new_ver() {
  ct_new_ver=$(wget --no-check-certificate -qO- -t2 -T3 https://api.github.com/repos/ginuerzh/gost/releases/latest | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g')
  if [[ -z ${ct_new_ver} ]]; then
    ct_new_ver="2.11.2"
    echo -e "${Error} gost 最新版本获取失败，正在下载v${ct_new_ver}版"
  else
    echo -e "${Info} gost 目前最新版本为 ${ct_new_ver}"
  fi
}
function check_file() {
  if test ! -d "/usr/lib/systemd/system/"; then
    mkdir /usr/lib/systemd/system
    chmod -R 777 /usr/lib/systemd/system
  fi
}
function check_nor_file() {
  rm -rf "$(pwd)"/gost
  rm -rf "$(pwd)"/gost.service
  rm -rf "$(pwd)"/config.json
  rm -rf /etc/gost
  rm -rf /usr/lib/systemd/system/gost.service
  rm -rf /usr/bin/gost
}
function Install_ct() {
  check_root
  check_nor_file
  Installation_dependency
  check_file
  check_sys

  echo -e "若为国内机器建议使用大陆镜像加速下载"
  read -e -p "是否使用？[y/n]:" addyn
  [[ -z ${addyn} ]] && addyn="n"
  if [[ ${addyn} == [Yy] ]]; then
    rm -rf gost-linux-"$bit"-"$ct_new_ver".gz
    wget --no-check-certificate https://gotunnel.oss-cn-shenzhen.aliyuncs.com/gost-linux-"$bit"-"$ct_new_ver".gz
    gunzip gost-linux-"$bit"-"$ct_new_ver".gz
    mv gost-linux-"$bit"-"$ct_new_ver" gost
    mv gost /usr/bin/gost
    chmod -R 777 /usr/bin/gost
    wget --no-check-certificate https://gotunnel.oss-cn-shenzhen.aliyuncs.com/gost.service && chmod -R 777 gost.service && mv gost.service /usr/lib/systemd/system
    mkdir /etc/gost && wget --no-check-certificate https://gotunnel.oss-cn-shenzhen.aliyuncs.com/config.json && mv config.json /etc/gost && chmod -R 777 /etc/gost
  else
    rm -rf gost-linux-"$bit"-"$ct_new_ver".gz
    wget --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v"$ct_new_ver"/gost-linux-"$bit"-"$ct_new_ver".gz
    gunzip gost-linux-"$bit"-"$ct_new_ver".gz
    mv gost-linux-"$bit"-"$ct_new_ver" gost
    mv gost /usr/bin/gost
    chmod -R 777 /usr/bin/gost
    wget --no-check-certificate https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/gost.service && chmod -R 777 gost.service && mv gost.service /usr/lib/systemd/system
    mkdir /etc/gost && wget --no-check-certificate https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/config.json && mv config.json /etc/gost && chmod -R 777 /etc/gost
  fi

  systemctl enable gost && systemctl restart gost
  echo "------------------------------"
  if test -a /usr/bin/gost -a /usr/lib/systemctl/gost.service -a /etc/gost/config.json; then
    echo "gost安装成功"
    rm -rf "$(pwd)"/gost
    rm -rf "$(pwd)"/gost.service
    rm -rf "$(pwd)"/config.json
  else
    echo "gost没有安装成功"
    rm -rf "$(pwd)"/gost
    rm -rf "$(pwd)"/gost.service
    rm -rf "$(pwd)"/config.json
    rm -rf "$(pwd)"/gost.sh
  fi
}
function Uninstall_ct() {
  rm -rf /usr/bin/gost
  rm -rf /usr/lib/systemd/system/gost.service
  rm -rf /etc/gost
  rm -rf "$(pwd)"/gost.sh
  echo "gost已经成功删除"
}
function Start_ct() {
  systemctl start gost
  echo "已启动"
}
function Stop_ct() {
  systemctl stop gost
  echo "已停止"
}
function Restart_ct() {
  rm -rf /etc/gost/config.json
  confstart
  writeconf
  conflast
  systemctl restart gost
  echo "已重读配置并重启"
}
function read_protocol() {
  echo -e "请问您要设置哪种功能: "
  echo -e "-----------------------------------"
  echo -e "[1] tcp+udp流量转发, 不加密"
  echo -e "说明: 一般设置在国内中转机上"
  echo -e "-----------------------------------"
  echo -e "[2] 加密隧道流量转发"
  echo -e "说明: 用于转发原本加密等级较低的流量, 一般设置在国内中转机上"
  echo -e "     选择此协议意味着你还有一台机器用于接收此加密流量, 之后须在那台机器上配置协议[3]进行对接"
  echo -e "-----------------------------------"
  echo -e "[3] 解密由gost传输而来的流量并转发"
  echo -e "说明: 对于经由gost加密中转的流量, 通过此选项进行解密并转发给本机的代理服务端口或转发给其他远程机器"
  echo -e "      一般设置在用于接收中转流量的国外机器上"
  echo -e "-----------------------------------"
  echo -e "[4] 一键安装ss/socks5/http代理"
  echo -e "说明: 使用gost内置的代理协议，轻量且易于管理"
  echo -e "-----------------------------------"
  echo -e "[5] 进阶：多落地均衡负载"
  echo -e "说明: 支持各种加密方式的简单均衡负载"
  echo -e "-----------------------------------"
  echo -e "[6] 进阶：转发CDN自选节点"
  echo -e "说明: 只需在中转机设置"
  echo -e "-----------------------------------"
  read -p "请选择: " numprotocol

  if [ "$numprotocol" == "1" ]; then
    flag_a="nonencrypt"
  elif [ "$numprotocol" == "2" ]; then
    encrypt
  elif [ "$numprotocol" == "3" ]; then
    decrypt
  elif [ "$numprotocol" == "4" ]; then
    proxy
  elif [ "$numprotocol" == "5" ]; then
    enpeer
  elif [ "$numprotocol" == "6" ]; then
    cdn
  else
    echo "type error, please try again"
    exit
  fi
}
function read_s_port() {
  if [ "$flag_a" == "ss" ]; then
    echo -e "-----------------------------------"
    read -p "请输入ss密码: " flag_b
  elif [ "$flag_a" == "socks" ]; then
    echo -e "-----------------------------------"
    read -p "请输入socks密码: " flag_b
  elif [ "$flag_a" == "http" ]; then
    echo -e "-----------------------------------"
    read -p "请输入http密码: " flag_b
  else
    echo -e "------------------------------------------------------------------"
    echo -e "请问你要将本机哪个端口接收到的流量进行转发?"
    read -p "请输入: " flag_b
  fi
}
function read_d_ip() {
  if [ "$flag_a" == "ss" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "请问您要设置的ss加密(仅提供常用的几种): "
    echo -e "-----------------------------------"
    echo -e "[1] aes-256-gcm"
    echo -e "[2] aes-256-cfb"
    echo -e "[3] chacha20-ietf-poly1305"
    echo -e "[4] chacha20"
    echo -e "[5] rc4-md5"
    echo -e "[6] AEAD_CHACHA20_POLY1305"
    echo -e "-----------------------------------"
    read -p "请选择ss加密方式: " ssencrypt

    if [ "$ssencrypt" == "1" ]; then
      flag_c="aes-256-gcm"
    elif [ "$ssencrypt" == "2" ]; then
      flag_c="aes-256-cfb"
    elif [ "$ssencrypt" == "3" ]; then
      flag_c="chacha20-ietf-poly1305"
    elif [ "$ssencrypt" == "4" ]; then
      flag_c="chacha20"
    elif [ "$ssencrypt" == "5" ]; then
      flag_c="rc4-md5"
    elif [ "$ssencrypt" == "6" ]; then
      flag_c="AEAD_CHACHA20_POLY1305"
    else
      echo "type error, please try again"
      exit
    fi
  elif [ "$flag_a" == "socks" ]; then
    echo -e "-----------------------------------"
    read -p "请输入socks用户名: " flag_c
  elif [ "$flag_a" == "http" ]; then
    echo -e "-----------------------------------"
    read -p "请输入http用户名: " flag_c
  elif [[ "$flag_a" == "peer"* ]]; then
    echo -e "------------------------------------------------------------------"
    echo -e "请输入落地列表文件名"
    read -e -p "自定义但不同配置应不重复，不用输入后缀，例如ips1、iplist2: " flag_c
    touch $flag_c.txt
    echo -e "------------------------------------------------------------------"
    echo -e "请依次输入你要均衡负载的落地ip与端口"
    while true; do
      echo -e "请问你要将本机从${flag_b}接收到的流量转发向的IP或域名?"
      read -p "请输入: " peer_ip
      echo -e "请问你要将本机从${flag_b}接收到的流量转发向${peer_ip}的哪个端口?"
      read -p "请输入: " peer_port
      echo -e "$peer_ip:$peer_port" >>$flag_c.txt
      read -e -p "是否继续添加落地？[Y/n]:" addyn
      [[ -z ${addyn} ]] && addyn="y"
      if [[ ${addyn} == [Nn] ]]; then
        echo -e "------------------------------------------------------------------"
        echo -e "已在root目录创建$flag_c.txt，您可以随时编辑该文件修改落地信息，重启gost即可生效"
        echo -e "------------------------------------------------------------------"
        break
      else
        echo -e "------------------------------------------------------------------"
        echo -e "继续添加均衡负载落地配置"
      fi
    done
  elif [[ "$flag_a" == "cdn"* ]]; then
    echo -e "------------------------------------------------------------------"
    echo -e "将本机从${flag_b}接收到的流量转发向的自选ip:"
    read -p "请输入: " flag_c
    echo -e "请问你要将本机从${flag_b}接收到的流量转发向${flag_c}的哪个端口?"
    echo -e "[1] 80"
    echo -e "[2] 443"
    echo -e "[3] 自定义端口（如8080等）"
    read -p "请选择端口: " cdnport
    if [ "$cdnport" == "1" ]; then
      flag_c="$flag_c:80"
    elif [ "$cdnport" == "2" ]; then
      flag_c="$flag_c:443"
    elif [ "$cdnport" == "3" ]; then
      read -p "请输入自定义端口: " customport
      flag_c="$flag_c:$customport"
    else
      echo "type error, please try again"
      exit
    fi
  else
    echo -e "------------------------------------------------------------------"
    echo -e "请问你要将本机从${flag_b}接收到的流量转发向哪个IP或域名?"
    echo -e "注: IP既可以是[远程机器/当前机器]的公网IP, 也可是以本机本地回环IP(即127.0.0.1)"
    echo -e "具体IP地址的填写, 取决于接收该流量的服务正在监听的IP"
    if [[ ${is_cert} == [Yy] ]]; then
      echo -e "注意: 落地机开启自定义tls证书，务必填写${Red_font_prefix}域名${Font_color_suffix}"
    fi
    read -p "请输入: " flag_c
  fi
}
function read_d_port() {
  if [ "$flag_a" == "ss" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "请问你要设置ss代理服务的端口?"
    read -p "请输入: " flag_d
  elif [ "$flag_a" == "socks" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "请问你要设置socks代理服务的端口?"
    read -p "请输入: " flag_d
  elif [ "$flag_a" == "http" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "请问你要设置http代理服务的端口?"
    read -p "请输入: " flag_d
  elif [[ "$flag_a" == "peer"* ]]; then
    echo -e "------------------------------------------------------------------"
    echo -e "您要设置的均衡负载策略: "
    echo -e "-----------------------------------"
    echo -e "[1] round - 轮询"
    echo -e "[2] random - 随机"
    echo -e "[3] fifo - 自上而下"
    echo -e "-----------------------------------"
    read -p "请选择均衡负载类型: " numstra

    if [ "$numstra" == "1" ]; then
      flag_d="round"
    elif [ "$numstra" == "2" ]; then
      flag_d="random"
    elif [ "$numstra" == "3" ]; then
      flag_d="fifo"
    else
      echo "type error, please try again"
      exit
    fi
  elif [[ "$flag_a" == "cdn"* ]]; then
    echo -e "------------------------------------------------------------------"
    read -p "请输入host:" flag_d
  else
    echo -e "------------------------------------------------------------------"
    echo -e "请问你要将本机从${flag_b}接收到的流量转发向${flag_c}的哪个端口?"
    read -p "请输入: " flag_d
    if [[ ${is_cert} == [Yy] ]]; then
      flag_d="$flag_d?secure=true"
    fi
  fi
}
function writerawconf() {
  echo $flag_a"/""$flag_b""#""$flag_c""#""$flag_d" >>$raw_conf_path
}
function rawconf() {
  read_protocol
  read_s_port
  read_d_ip
  read_d_port
  writerawconf
}
function eachconf_retrieve() {
  d_server=${trans_conf#*#}
  d_port=${d_server#*#}
  d_ip=${d_server%#*}
  flag_s_port=${trans_conf%%#*}
  s_port=${flag_s_port#*/}
  is_encrypt=${flag_s_port%/*}
}
function confstart() {
  echo "{
    \"Debug\": true,
    \"Retries\": 0,
    \"ServeNodes\": [" >>$gost_conf_path
}
function multiconfstart() {
  echo "        {
            \"Retries\": 0,
            \"ServeNodes\": [" >>$gost_conf_path
}
function conflast() {
  echo "    ]
}" >>$gost_conf_path
}
function multiconflast() {
  if [ $i -eq $count_line ]; then
    echo "            ]
        }" >>$gost_conf_path
  else
    echo "            ]
        }," >>$gost_conf_path
  fi
}
function encrypt() {
  echo -e "请问您要设置的转发传输类型: "
  echo -e "-----------------------------------"
  echo -e "[1] tls隧道"
  echo -e "[2] ws隧道"
  echo -e "[3] wss隧道"
  echo -e "注意: 同一则转发，中转与落地传输类型必须对应！本脚本默认开启tcp+udp"
  echo -e "-----------------------------------"
  read -p "请选择转发传输类型: " numencrypt

  if [ "$numencrypt" == "1" ]; then
    flag_a="encrypttls"
    echo -e "注意: 选择 是 将针对落地的自定义证书开启证书校验保证安全性，稍后落地机务必填写${Red_font_prefix}域名${Font_color_suffix}"
    read -e -p "落地机是否开启了自定义tls证书？[y/n]:" is_cert
  elif [ "$numencrypt" == "2" ]; then
    flag_a="encryptws"
  elif [ "$numencrypt" == "3" ]; then
    flag_a="encryptwss"
    echo -e "注意: 选择 是 将针对落地的自定义证书开启证书校验保证安全性，稍后落地机务必填写${Red_font_prefix}域名${Font_color_suffix}"
    read -e -p "落地机是否开启了自定义tls证书？[y/n]:" is_cert
  else
    echo "type error, please try again"
    exit
  fi
}
function enpeer() {
  echo -e "请问您要设置的均衡负载传输类型: "
  echo -e "-----------------------------------"
  echo -e "[1] 不加密转发"
  echo -e "[2] tls隧道"
  echo -e "[3] ws隧道"
  echo -e "[4] wss隧道"
  echo -e "注意: 同一则转发，中转与落地传输类型必须对应！本脚本默认同一配置的传输类型相同"
  echo -e "此脚本仅支持简单型均衡负载"
  echo -e "-----------------------------------"
  read -p "请选择转发传输类型: " numpeer

  if [ "$numpeer" == "1" ]; then
    flag_a="peerno"
  elif [ "$numpeer" == "2" ]; then
    flag_a="peertls"
  elif [ "$numpeer" == "3" ]; then
    flag_a="peerws"
  elif [ "$numpeer" == "4" ]; then
    flag_a="peerwss"

  else
    echo "type error, please try again"
    exit
  fi
}
function cdn() {
  echo -e "请问您要设置的CDN传输类型: "
  echo -e "-----------------------------------"
  echo -e "[1] 不加密转发"
  echo -e "[2] ws隧道"
  echo -e "[3] wss隧道"
  echo -e "注意: 同一则转发，中转与落地传输类型必须对应！"
  echo -e "此功能只需在中转机设置"
  echo -e "-----------------------------------"
  read -p "请选择CDN转发传输类型: " numcdn

  if [ "$numcdn" == "1" ]; then
    flag_a="cdnno"
  elif [ "$numcdn" == "2" ]; then
    flag_a="cdnws"
  elif [ "$numcdn" == "3" ]; then
    flag_a="cdnwss"
  else
    echo "type error, please try again"
    exit
  fi
}
function cert() {
  echo -e "-----------------------------------"
  echo -e "[1] ACME一键申请证书"
  echo -e "[2] 手动上传证书"
  echo -e "-----------------------------------"
  echo -e "说明: 仅用于落地机配置，默认使用的gost内置的证书可能带来安全问题，使用自定义证书提高安全性"
  echo -e "     配置后对本机所有tls/wss解密生效，无需再次设置"
  read -p "请选择证书生成方式: " numcert

  if [ "$numcert" == "1" ]; then
    check_sys
    if [[ ${release} == "centos" ]]; then
      yum install -y socat
    else
      apt-get install -y socat
    fi
    read -p "请输入ZeroSSL的账户邮箱(至 zerossl.com 注册即可)：" zeromail
    read -p "请输入解析到本机的域名：" domain
    curl https://get.acme.sh | sh
    "$HOME"/.acme.sh/acme.sh --set-default-ca --server zerossl
    "$HOME"/.acme.sh/acme.sh --register-account -m "${zeromail}" --server zerossl
    echo -e "ACME证书申请程序安装成功"
    echo -e "-----------------------------------"
    echo -e "[1] HTTP申请（需要80端口未占用）"
    echo -e "[2] Cloudflare DNS API 申请（需要输入APIKEY）"
    echo -e "-----------------------------------"
    read -p "请选择证书申请方式: " certmethod
    if [ "certmethod" == "1" ]; then
      echo -e "请确认本机${Red_font_prefix}80${Font_color_suffix}端口未被占用, 否则会申请失败"
      if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force; then
        echo -e "SSL 证书生成成功，默认申请高安全性的ECC证书"
        if [ ! -d "$HOME/gost_cert" ]; then
          mkdir $HOME/gost_cert
        fi
        if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath $HOME/gost_cert/cert.pem --keypath $HOME/gost_cert/key.pem --ecc --force; then
          echo -e "SSL 证书配置成功，且会自动续签，证书及秘钥位于用户目录下的 ${Red_font_prefix}gost_cert${Font_color_suffix} 目录"
          echo -e "证书目录名与证书文件名请勿更改; 删除 gost_cert 目录后用脚本重启,即自动启用gost内置证书"
          echo -e "-----------------------------------"
        fi
      else
        echo -e "SSL 证书生成失败"
        exit 1
      fi
    else
      read -p "请输入Cloudflare账户邮箱：" cfmail
      read -p "请输入Cloudflare Global API Key：" cfkey
      export CF_Key="${cfkey}"
      export CF_Email="${cfmail}"
      if "$HOME"/.acme.sh/acme.sh --issue --dns dns_cf -d "${domain}" --standalone -k ec-256 --force; then
        echo -e "SSL 证书生成成功，默认申请高安全性的ECC证书"
        if [ ! -d "$HOME/gost_cert" ]; then
          mkdir $HOME/gost_cert
        fi
        if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath $HOME/gost_cert/cert.pem --keypath $HOME/gost_cert/key.pem --ecc --force; then
          echo -e "SSL 证书配置成功，且会自动续签，证书及秘钥位于用户目录下的 ${Red_font_prefix}gost_cert${Font_color_suffix} 目录"
          echo -e "证书目录名与证书文件名请勿更改; 删除 gost_cert 目录后使用脚本重启, 即重新启用gost内置证书"
          echo -e "-----------------------------------"
        fi
      else
        echo -e "SSL 证书生成失败"
        exit 1
      fi
    fi

  elif [ "$numcert" == "2" ]; then
    if [ ! -d "$HOME/gost_cert" ]; then
      mkdir $HOME/gost_cert
    fi
    echo -e "-----------------------------------"
    echo -e "已在用户目录建立 ${Red_font_prefix}gost_cert${Font_color_suffix} 目录，请将证书文件 cert.pem 与秘钥文件 key.pem 上传到该目录"
    echo -e "证书与秘钥文件名必须与上述一致，目录名也请勿更改"
    echo -e "上传成功后，用脚本重启gost会自动启用，无需再设置; 删除 gost_cert 目录后用脚本重启,即重新启用gost内置证书"
    echo -e "-----------------------------------"
  else
    echo "type error, please try again"
    exit
  fi
}
function decrypt() {
  echo -e "请问您要设置的解密传输类型: "
  echo -e "-----------------------------------"
  echo -e "[1] tls"
  echo -e "[2] ws"
  echo -e "[3] wss"
  echo -e "注意: 同一则转发，中转与落地传输类型必须对应！本脚本默认开启tcp+udp"
  echo -e "-----------------------------------"
  read -p "请选择解密传输类型: " numdecrypt

  if [ "$numdecrypt" == "1" ]; then
    flag_a="decrypttls"
  elif [ "$numdecrypt" == "2" ]; then
    flag_a="decryptws"
  elif [ "$numdecrypt" == "3" ]; then
    flag_a="decryptwss"
  else
    echo "type error, please try again"
    exit
  fi
}
function proxy() {
  echo -e "------------------------------------------------------------------"
  echo -e "请问您要设置的代理类型: "
  echo -e "-----------------------------------"
  echo -e "[1] shadowsocks"
  echo -e "[2] socks5(强烈建议加隧道用于Telegram代理)"
  echo -e "[3] http"
  echo -e "-----------------------------------"
  read -p "请选择代理类型: " numproxy
  if [ "$numproxy" == "1" ]; then
    flag_a="ss"
  elif [ "$numproxy" == "2" ]; then
    flag_a="socks"
  elif [ "$numproxy" == "3" ]; then
    flag_a="http"
  else
    echo "type error, please try again"
    exit
  fi
}
function method() {
  if [ $i -eq 1 ]; then
    if [ "$is_encrypt" == "nonencrypt" ]; then
      echo "        \"tcp://:$s_port/$d_ip:$d_port\",
        \"udp://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnno" ]; then
      echo "        \"tcp://:$s_port/$d_ip?host=$d_port\",
        \"udp://:$s_port/$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerno" ]; then
      echo "        \"tcp://:$s_port?ip=/root/$d_ip.txt&strategy=$d_port\",
        \"udp://:$s_port?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encrypttls" ]; then
      echo "        \"tcp://:$s_port\",
        \"udp://:$s_port\"
    ],
    \"ChainNodes\": [
        \"relay+tls://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encryptws" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+ws://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encryptwss" ]; then
      echo "        \"tcp://:$s_port\",
		  \"udp://:$s_port\"
	],
	\"ChainNodes\": [
		\"relay+wss://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peertls" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+tls://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerws" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+ws://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerwss" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+wss://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnws" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+ws://$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnwss" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+wss://$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "decrypttls" ]; then
      if [ -d "$HOME/gost_cert" ]; then
        echo "        \"relay+tls://:$s_port/$d_ip:$d_port?cert=/root/gost_cert/cert.pem&key=/root/gost_cert/key.pem\"" >>$gost_conf_path
      else
        echo "        \"relay+tls://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
      fi
    elif [ "$is_encrypt" == "decryptws" ]; then
      echo "        \"relay+ws://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "decryptwss" ]; then
      if [ -d "$HOME/gost_cert" ]; then
        echo "        \"relay+wss://:$s_port/$d_ip:$d_port?cert=/root/gost_cert/cert.pem&key=/root/gost_cert/key.pem\"" >>$gost_conf_path
      else
        echo "        \"relay+wss://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
      fi
    elif [ "$is_encrypt" == "ss" ]; then
      echo "        \"ss://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "socks" ]; then
      echo "        \"socks5://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "http" ]; then
      echo "        \"http://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    else
      echo "config error"
    fi
  elif [ $i -gt 1 ]; then
    if [ "$is_encrypt" == "nonencrypt" ]; then
      echo "                \"tcp://:$s_port/$d_ip:$d_port\",
                \"udp://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerno" ]; then
      echo "                \"tcp://:$s_port?ip=/root/$d_ip.txt&strategy=$d_port\",
                \"udp://:$s_port?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnno" ]; then
      echo "                \"tcp://:$s_port/$d_ip?host=$d_port\",
                \"udp://:$s_port/$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encrypttls" ]; then
      echo "                \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+tls://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encryptws" ]; then
      echo "                \"tcp://:$s_port\",
	            \"udp://:$s_port\"
	        ],
	        \"ChainNodes\": [
	            \"relay+ws://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encryptwss" ]; then
      echo "                \"tcp://:$s_port\",
		        \"udp://:$s_port\"
		    ],
		    \"ChainNodes\": [
		        \"relay+wss://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peertls" ]; then
      echo "                \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+tls://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerws" ]; then
      echo "                \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+ws://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerwss" ]; then
      echo "                \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+wss://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnws" ]; then
      echo "                \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+ws://$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnwss" ]; then
      echo "                 \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+wss://$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "decrypttls" ]; then
      if [ -d "$HOME/gost_cert" ]; then
        echo "        		  \"relay+tls://:$s_port/$d_ip:$d_port?cert=/root/gost_cert/cert.pem&key=/root/gost_cert/key.pem\"" >>$gost_conf_path
      else
        echo "        		  \"relay+tls://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
      fi
    elif [ "$is_encrypt" == "decryptws" ]; then
      echo "        		  \"relay+ws://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "decryptwss" ]; then
      if [ -d "$HOME/gost_cert" ]; then
        echo "        		  \"relay+wss://:$s_port/$d_ip:$d_port?cert=/root/gost_cert/cert.pem&key=/root/gost_cert/key.pem\"" >>$gost_conf_path
      else
        echo "        		  \"relay+wss://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
      fi
    elif [ "$is_encrypt" == "ss" ]; then
      echo "        \"ss://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "socks" ]; then
      echo "        \"socks5://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "http" ]; then
      echo "        \"http://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    else
      echo "config error"
    fi
  else
    echo "config error"
    exit
  fi
}

function writeconf() {
  count_line=$(awk 'END{print NR}' $raw_conf_path)
  for ((i = 1; i <= $count_line; i++)); do
    if [ $i -eq 1 ]; then
      trans_conf=$(sed -n "${i}p" $raw_conf_path)
      eachconf_retrieve
      method
    elif [ $i -gt 1 ]; then
      if [ $i -eq 2 ]; then
        echo "    ],
    \"Routes\": [" >>$gost_conf_path
        trans_conf=$(sed -n "${i}p" $raw_conf_path)
        eachconf_retrieve
        multiconfstart
        method
        multiconflast
      else
        trans_conf=$(sed -n "${i}p" $raw_conf_path)
        eachconf_retrieve
        multiconfstart
        method
        multiconflast
      fi
    fi
  done
}
function show_all_conf() {
  echo -e "                      GOST 配置                        "
  echo -e "--------------------------------------------------------"
  echo -e "序号|方法\t    |本地端口\t|目的地地址:目的地端口"
  echo -e "--------------------------------------------------------"

  count_line=$(awk 'END{print NR}' $raw_conf_path)
  for ((i = 1; i <= $count_line; i++)); do
    trans_conf=$(sed -n "${i}p" $raw_conf_path)
    eachconf_retrieve

    if [ "$is_encrypt" == "nonencrypt" ]; then
      str="不加密中转"
    elif [ "$is_encrypt" == "encrypttls" ]; then
      str=" tls隧道 "
    elif [ "$is_encrypt" == "encryptws" ]; then
      str="  ws隧道 "
    elif [ "$is_encrypt" == "encryptwss" ]; then
      str=" wss隧道 "
    elif [ "$is_encrypt" == "peerno" ]; then
      str=" 不加密均衡负载 "
    elif [ "$is_encrypt" == "peertls" ]; then
      str=" tls隧道均衡负载 "
    elif [ "$is_encrypt" == "peerws" ]; then
      str="  ws隧道均衡负载 "
    elif [ "$is_encrypt" == "peerwss" ]; then
      str=" wss隧道均衡负载 "
    elif [ "$is_encrypt" == "decrypttls" ]; then
      str=" tls解密 "
    elif [ "$is_encrypt" == "decryptws" ]; then
      str="  ws解密 "
    elif [ "$is_encrypt" == "decryptwss" ]; then
      str=" wss解密 "
    elif [ "$is_encrypt" == "ss" ]; then
      str="   ss   "
    elif [ "$is_encrypt" == "socks" ]; then
      str=" socks5 "
    elif [ "$is_encrypt" == "http" ]; then
      str=" http "
    elif [ "$is_encrypt" == "cdnno" ]; then
      str="不加密转发CDN"
    elif [ "$is_encrypt" == "cdnws" ]; then
      str="ws隧道转发CDN"
    elif [ "$is_encrypt" == "cdnwss" ]; then
      str="wss隧道转发CDN"
    else
      str=""
    fi

    echo -e " $i  |$str  |$s_port\t|$d_ip:$d_port"
    echo -e "--------------------------------------------------------"
  done
}

cron_restart() {
  echo -e "------------------------------------------------------------------"
  echo -e "gost定时重启任务: "
  echo -e "-----------------------------------"
  echo -e "[1] 配置gost定时重启任务"
  echo -e "[2] 删除gost定时重启任务"
  echo -e "-----------------------------------"
  read -p "请选择: " numcron
  if [ "$numcron" == "1" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "gost定时重启任务类型: "
    echo -e "-----------------------------------"
    echo -e "[1] 每？小时重启"
    echo -e "[2] 每日？点重启"
    echo -e "-----------------------------------"
    read -p "请选择: " numcrontype
    if [ "$numcrontype" == "1" ]; then
      echo -e "-----------------------------------"
      read -p "每？小时重启: " cronhr
      echo "0 0 */$cronhr * * ? * systemctl restart gost" >>/etc/crontab
      echo -e "定时重启设置成功！"
    elif [ "$numcrontype" == "2" ]; then
      echo -e "-----------------------------------"
      read -p "每日？点重启: " cronhr
      echo "0 0 $cronhr * * ? systemctl restart gost" >>/etc/crontab
      echo -e "定时重启设置成功！"
    else
      echo "type error, please try again"
      exit
    fi
  elif [ "$numcron" == "2" ]; then
    sed -i "/gost/d" /etc/crontab
    echo -e "定时重启任务删除完成！"
  else
    echo "type error, please try again"
    exit
  fi
}

update_sh() {
  ol_version=$(curl -L -s --connect-timeout 5 https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/gost.sh | grep "shell_version=" | head -1 | awk -F '=|"' '{print $3}')
  if [ -n "$ol_version" ]; then
    if [[ "$shell_version" != "$ol_version" ]]; then
      echo -e "存在新版本，是否更新 [Y/N]?"
      read -r update_confirm
      case $update_confirm in
      [yY][eE][sS] | [yY])
        wget -N --no-check-certificate https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/gost.sh
        echo -e "更新完成"
        exit 0
        ;;
      *) ;;

      esac
    else
      echo -e "                 ${Green_font_prefix}当前版本为最新版本！${Font_color_suffix}"
    fi
  else
    echo -e "                 ${Red_font_prefix}脚本最新版本获取失败，请检查与github的连接！${Font_color_suffix}"
  fi
}

update_sh
echo && echo -e "                 gost 一键安装配置脚本"${Red_font_prefix}[${shell_version}]${Font_color_suffix}"
  ----------- KANIKIG -----------
  特性: (1)本脚本采用systemd及gost配置文件对gost进行管理
        (2)能够在不借助其他工具(如screen)的情况下实现多条转发规则同时生效
        (3)机器reboot后转发不失效
  功能: (1)tcp+udp不加密转发, (2)中转机加密转发, (3)落地机解密对接转发

 ${Green_font_prefix}1.${Font_color_suffix} 安装 gost
 ${Green_font_prefix}2.${Font_color_suffix} 更新 gost
 ${Green_font_prefix}3.${Font_color_suffix} 卸载 gost
————————————
 ${Green_font_prefix}4.${Font_color_suffix} 启动 gost
 ${Green_font_prefix}5.${Font_color_suffix} 停止 gost
 ${Green_font_prefix}6.${Font_color_suffix} 重启 gost
————————————
 ${Green_font_prefix}7.${Font_color_suffix} 新增gost转发配置
 ${Green_font_prefix}8.${Font_color_suffix} 查看现有gost配置
 ${Green_font_prefix}9.${Font_color_suffix} 删除一则gost配置
————————————
 ${Green_font_prefix}10.${Font_color_suffix} gost定时重启配置
 ${Green_font_prefix}11.${Font_color_suffix} 自定义TLS证书配置
————————————" && echo
read -e -p " 请输入数字 [1-9]:" num
case "$num" in
1)
  Install_ct
  ;;
2)
  checknew
  ;;
3)
  Uninstall_ct
  ;;
4)
  Start_ct
  ;;
5)
  Stop_ct
  ;;
6)
  Restart_ct
  ;;
7)
  rawconf
  rm -rf /etc/gost/config.json
  confstart
  writeconf
  conflast
  systemctl restart gost
  echo -e "配置已生效，当前配置如下"
  echo -e "--------------------------------------------------------"
  show_all_conf
  ;;
8)
  show_all_conf
  ;;
9)
  show_all_conf
  read -p "请输入你要删除的配置编号：" numdelete
  if echo $numdelete | grep -q '[0-9]'; then
    sed -i "${numdelete}d" $raw_conf_path
    rm -rf /etc/gost/config.json
    confstart
    writeconf
    conflast
    systemctl restart gost
    echo -e "配置已删除，服务已重启"
  else
    echo "请输入正确数字"
  fi
  ;;
10)
  cron_restart
  ;;
11)
  cert
  ;;
*)
  echo "请输入正确数字 [1-9]"
  ;;
esac

}

adddhcp_root() {
echo " --------------------------------------------------------------------"
echo -e " ---------------------- \033[33m一键修改root账户密码\033[0m ------------------------ "
echo -e " ------- \033[33m功能 1、修改Ubuntu的root密码\033[0m ------------------------------- "
echo -e " ------- \033[33m功能 2、持久化root密码，可永久连接\033[0m ------------------------- "
echo " --------------------------------------------------------------------"

echo -e "\033[32m 确认你的root密码（两次输入且无提示）... \033[0m"
sudo passwd root

echo -e "\033[32m 修改成功！！！ \033[0m"

sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
sudo service sshd restart
sudo -i
}

addemotn_sshd() {

echo "SSH开启密码、ROOT登录"
sshd_file="/etc/ssh/sshd_config"
cp -n $sshd_file /etc/ssh/sshd_config.bak
sed -i "s|^#\?PasswordAuthentication.*|PasswordAuthentication yes|" $sshd_file
sed -i "s|^#\?PermitRootLogin.*|PermitRootLogin yes|" $sshd_file
systemctl restart sshd;systemctl restart ssh;service sshd restart;service ssh restart
    echo -e "\n\n"
}

# 一键修改 SSH 端口
sessh_22() {
    read -p "请输入新的 SSH 端口: " new_port
    sed -i "s/Port [0-9]*/Port $new_port/" /etc/ssh/sshd_config
    systemctl restart sshd
    echo "SSH 端口已修改为 $new_port"
}

grouter_IPv4e() {
#!/usr/bin/env bash
# By 网络跳越(hijk)
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
bold(){
    echo -e "\033[1m\033[01m$1\033[0m"
}

Green_font_prefix="\033[32m" 
Red_font_prefix="\033[31m" 
Green_background_prefix="\033[42;37m" 
Red_background_prefix="\033[41;37m" 
Font_color_suffix="\033[0m"

function preferIPV4(){
    if [[ -f "/etc/gai.conf" ]]; then
        sed -i '/^precedence \:\:ffff\:0\:0/d' /etc/gai.conf
        sed -i '/^label 2002\:\:\/16/d' /etc/gai.conf
    fi
    if [[ -z $1 ]]; then
        echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
        echo
        green " VPS服务器已成功设置为 IPv4 优先访问网络"

    else
        green " ================================================== "
        yellow " 请为服务器设置 IPv4 还是 IPv6 优先访问: "
        echo
        green " 1 优先 IPv4 访问网络"
        green " 2 优先 IPv6 访问网络"
        green " 3 删除 IPv4 或 IPv6 优先访问的设置, 还原为系统默认配置"
        echo
        read -p "请选择 IPv4 还是 IPv6 优先访问? 直接回车默认选1, 请输入[1/2/3]:" isPreferIPv4Input
        isPreferIPv4Input=${isPreferIPv4Input:-1}
        if [[ ${isPreferIPv4Input} == [2] ]]; then
            # 设置 IPv6 优先
            echo "label 2002::/16   2" >> /etc/gai.conf
            echo
            green " VPS服务器已成功设置为 IPv6 优先访问网络 "
        elif [[ ${isPreferIPv4Input} == [3] ]]; then
            echo
            green " VPS服务器 已删除 IPv4 或 IPv6 优先访问的设置, 还原为系统默认配置 "  
        else
            # 设置 IPv4 优先
            echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
            
            echo
            green " VPS服务器已成功设置为 IPv4 优先访问网络 "    
        fi
        green " ================================================== "
        echo
        yellow " 验证 IPv4 或 IPv6 访问网络优先级测试, 命令: curl ip.p3terx.com " 
        echo  
        curl ip.p3terx.com
        echo
        green " 上面信息显示："   
        green " 如果是IPv4地址->则VPS服务器已设置为 IPv4优先访问 "  
	green " 如果是IPv6地址->则VPS服务器已设置为 IPv6优先访问 "  
        green " ================================================== "

    fi
    echo
}
function start_menu(){
    clear
    green " 1. 设置 VPS服务器 IPv4 还是 IPv6 网络优先访问" 
    echo
    green " =================================================="
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
           preferIPV4 "redo"
	;;
        0 )
            exit 1
        ;;
        * )
            clear
            red "请输入正确数字 !"
            sleep 2s
            start_menu
        ;;
    esac
}
start_menu "first"
}

is_OpenSSH() {

OPENSSH_VERSION="9.8p1"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法检测操作系统类型。"
    exit 1
fi
wait_for_lock() {
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        echo "等待dpkg锁释放..."
        sleep 1
    done
}

fix_dpkg() {
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}

install_dependencies() {
    case $OS in
        ubuntu|debian)
            wait_for_lock
            fix_dpkg
            DEBIAN_FRONTEND=noninteractive apt update
            DEBIAN_FRONTEND=noninteractive apt install -y build-essential zlib1g-dev libssl-dev libpam0g-dev wget ntpdate -o Dpkg::Options::="--force-confnew"
            ;;
        centos|rhel|fedora)
            yum install -y epel-release
            yum groupinstall -y "Development Tools"
            yum install -y zlib-devel openssl-devel pam-devel wget ntpdate
            ;;
        alpine)
            apk add build-base zlib-dev openssl-dev pam-dev wget ntpdate
            ;;
        *)
            echo "不支持的操作系统：$OS"
            exit 1
            ;;
    esac
}

install_openssh() {
    wget --no-check-certificate https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz
    tar -xzf openssh-${OPENSSH_VERSION}.tar.gz
    cd openssh-${OPENSSH_VERSION}
    ./configure
    make
    make install
}

restart_ssh() {
    case $OS in
        ubuntu|debian)
            systemctl restart ssh
            ;;
        centos|rhel|fedora)
            systemctl restart sshd
            ;;
        alpine)
            rc-service sshd restart
            ;;
        *)
            echo "不支持的操作系统：$OS"
            exit 1
            ;;
    esac
}

set_path_priority() {
    NEW_SSH_PATH=$(which sshd)
    NEW_SSH_DIR=$(dirname "$NEW_SSH_PATH")

    if [[ ":$PATH:" != *":$NEW_SSH_DIR:"* ]]; then
        export PATH="$NEW_SSH_DIR:$PATH"
        echo "export PATH=\"$NEW_SSH_DIR:\$PATH\"" >> ~/.bashrc
    fi
}

# 验证更新
verify_installation() {
    echo "SSH版本信息："
    ssh -V
    sshd -V
}

# 清理下载的文件
clean_up() {
    cd ..
    rm -rf openssh-${OPENSSH_VERSION}*
}

# 标题
check_openssh_test() {
echo "SSH高危漏洞修复工具"
echo "--------------------------"
}
check_openssh_version() {
    current_version=$(ssh -V 2>&1 | awk '{print $1}' | cut -d_ -f2 | cut -d'p' -f1)
    min_version=8.5
    max_version=9.7
    if awk -v ver="$current_version" -v min="$min_version" -v max="$max_version" 'BEGIN{if(ver>=min && ver<=max) exit 0; else exit 1}'; then
      check_openssh_test
      echo "SSH版本: $current_version  在8.5到9.7之间，需要修复。"
      read -p "确定继续吗？(Y/N): " choice
          case "$choice" in
            [Yy])
              install_dependencies
              install_openssh
              restart_ssh
              set_path_priority
              verify_installation
              clean_up
              ;;
            [Nn])
              echo "已取消"
              exit 1
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              exit 1
              ;;
          esac
    else
      check_openssh_test
      echo "SSH版本: $current_version  不在8.5到9.7之间，无需修复。"
      exit 1
    fi
}
check_openssh_version
}

check_whiptailcc() {
#自动防御cc
curl -ko install.sh --connect-timeout 300 --retry 5 --retry-delay 3 https://zhangge.net/wp-content/uploads/files/cckiller/install.sh?ver=1.0.8 && sh install.sh -i

}

do_CentOS7t() {
    if [ -f /etc/yum.repos.d/CentOS-Base.repo ]; then
        echo "正在更换CentOS的源为阿里云源..."
        sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
        cat << 'EOF' | sudo tee /etc/yum.repos.d/CentOS-Base.repo
[base]
name=CentOS-$releasever - Base - 阿里云镜像
baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

# 可选的，添加阿里云的额外源
[extras]
name=CentOS-$releasever - Extras - 阿里云镜像
baseurl=http://mirrors.aliyun.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

# 可选的，添加阿里云的更新源
[updates]
name=CentOS-$releasever - Updates - 阿里云镜像
baseurl=http://mirrors.aliyun.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
EOF
        sudo yum clean all
        sudo yum makecache
        echo "CentOS源更换完成。"
sudo yum install -y curl wget vim nano socat firewalld pciutils epel-release jq bc nmap-ncat bind-utils iproute iproute2 python python3 python3-pip git lrzsz update net-tools automake cmake gzip bzip2 zip unzip kernel kernel-devel kernel-headers git-all screen c++ sendmail mailx 2> /dev/null || sudo apt update && sudo apt install -y curl wget vim nano socat firewalld pciutils jq bc netcat-openbsd dnsutils iproute2 python python3 python3-pip git lrzsz gcc gcc-c++ net-tools automake cmake gzip bzip2 zip unzip kernel kernel-devel kernel-headers git-all screen c++ sendmail mailx
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    iptables-save
    echo "CentOS源安装更新完成。"        
    else
        echo "CentOS源配置文件不存在。"
    fi
}

swap (){
mkdir /SwapDir
cd /SwapDir
  clear
echo -e "请输入需要添加的swap，建议为内存的2倍！"
read -p "请输入swap数值:" swapsize
echo
dd if=/dev/zero of=/SwapDir/swap bs=1M count=${swapsize}
chmod 0600 swap
mkswap /SwapDir/swap #把这个分区变成swap分区
swapon /SwapDir/swap #把刚建的swap分区设成为有效状态
echo "/SwapDir/swap swap swap defaults 0 0">>/etc/fstab #增加新的swap开机自动启动
echo
echo -e "\033[31m 完成\!恭喜\！系统交换添加成功\！\033[0m"
echo -e "\033[33m 您的系统交换是 \: \033[0m"
echo
free -h
}

install_6.0(){
if [ -f /etc/redhat-release ]; then    
wget -O install.sh http://www.btkaixin.net/install/install_6.0.sh && bash install.sh
elif [ -f /etc/debian_version ]; then
wget -O install.sh http://www.btkaixin.net/install/install_6.0.sh && bash install.sh
else
exit 1
fi
}

xray22() {
 read -p " 请输入要更改的系统主机名：" hostname
[[ -z "${hostname}" ]]
	hostname=${hostname,,}
sudo hostnamectl set-hostname $hostname
hostname
red " 完成\!恭喜\！系统主机名修改成功。${YELLOW} ${blu} $hostname"
}

xd() {
bash <(wget -qO- 'sh.xdmb.xyz/xiandan/xd.sh')
}

install_OpenVZ() {
#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
SERVICE_NAME='haproxy-lkl'
HAPROXY_LKL_DIR="/usr/local/$SERVICE_NAME"

BASE_URL='https://github.com/kuoruan/shell-scripts/raw/master/ovz-bbr'
HAPROXY_BIN_URL="${BASE_URL}/bin/haproxy.linux2628_x86_64"
HAPROXY_LKL_BIN_URL="${BASE_URL}/bin/haproxy-lkl.sh"
HAPROXY_LKL_SERVICE_FILE_DEBIAN_URL="${BASE_URL}/startup/haproxy-lkl.init.debain"
HAPROXY_LKL_SERVICE_FILE_REDHAT_URL="${BASE_URL}/startup/haproxy-lkl.init.redhat"
HAPROXY_LKL_SYSTEMD_FILE_URL="${BASE_URL}/startup/haproxy-lkl.systemd"
LKL_LIB_URL="${BASE_URL}/lib64/liblkl-hijack.so-20170724"
LKL_LIB_MD5='b50fc6a7ccfc70c76f44506814e7e18b'

# 需要 BBR 加速的端口
ACCELERATE_PORT=
clear
cat >&2 <<-'EOF'
#######################################################
# OpenVZ BBR 一键安装脚本                             #
# 该脚本用于在 OpenVZ 服务器上安装配置 Google BBR     #
#######################################################
EOF
command_exists() {
	command -v "$@" >/dev/null 2>&1
}

check_root() {
	local user="$(id -un 2>/dev/null || true)"
	if [ "$user" != "root" ]; then
		cat >&2 <<-'EOF'
		权限错误, 请使用 root 用户运行此脚本!
		EOF
		exit 1
	fi
}

check_ovz() {
	if [ ! -d /proc/vz ]; then
		cat >&2 <<-'EOF'
		当前服务器好像不是 OpenVZ 架构，你可以直接更换内核以启用 BBR。
		当然，你也可以继续安装。
		EOF
		
	fi
}

check_ldd() {
	local ldd_version="$(ldd --version 2>/dev/null | grep 'ldd' | rev | cut -d ' ' -f1 | rev)"
	if [ -n "$ldd_version" ]; then
		if [ "${ldd_version%.*}" -eq "2" -a "${ldd_version#*.}" -lt "14" ] || \
		[ "${ldd_version%.*}" -lt "2" ]; then
			cat >&2 <<-EOF
			当前服务器的 glibc 版本为 $ldd_version。
			最低版本需求 2.14，低于这个版本无法正常使用。
			请先更新 glibc 之后再运行脚本。
			EOF
			exit 1
	  fi
	else
		cat >&2 <<-EOF
		获取 glibc 版本失败，请手动检查：
		    ldd --version
		最低版本需求 2.14，低于这个版本可能无法正常使用。
		EOF

		( set -x; ldd --version 2>/dev/null )
		
	fi
}

check_arch() {
	architecture=$(uname -m)
	case $architecture in
		amd64|x86_64)
			;;
		*)
			cat 1>&2 <<-EOF
			当前脚本仅支持 64 位系统，你的系统为: $architecture
			你可以尝试从源码编译安装 Linux Kernel Library
			    https://github.com/lkl/linux
			EOF
			exit 1
			;;
	esac
}

get_os_info() {
	lsb_dist=''
	dist_version=''
	if command_exists lsb_release; then
		lsb_dist="$(lsb_release -si)"
	fi

	if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
		lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/debian_version ]; then
		lsb_dist='debian'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/fedora-release ]; then
		lsb_dist='fedora'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/oracle-release ]; then
		lsb_dist='oracleserver'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/centos-release ]; then
		lsb_dist='centos'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/redhat-release ]; then
		lsb_dist='redhat'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/photon-release ]; then
		lsb_dist='photon'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi

	lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

	if [ "${lsb_dist}" = "redhatenterpriseserver" ]; then
		lsb_dist='redhat'
	fi

	case "$lsb_dist" in
		ubuntu)
			if command_exists lsb_release; then
				dist_version="$(lsb_release --codename | cut -f2)"
			fi
			if [ -z "$dist_version" ] && [ -r /etc/lsb-release ]; then
				dist_version="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
			fi
		;;

		debian|raspbian)
			dist_version="$(cat /etc/debian_version | sed 's/\/.*//' | sed 's/\..*//')"
			case "$dist_version" in
				9)
					dist_version="stretch"
				;;
				8)
					dist_version="jessie"
				;;
				7)
					dist_version="wheezy"
				;;
			esac
		;;

		oracleserver)
			lsb_dist="oraclelinux"
			dist_version="$(rpm -q --whatprovides redhat-release --queryformat "%{VERSION}\n" | sed 's/\/.*//' | sed 's/\..*//' | sed 's/Server*//')"
		;;

		fedora|centos|redhat)
			dist_version="$(rpm -q --whatprovides ${lsb_dist}-release --queryformat "%{VERSION}\n" | sed 's/\/.*//' | sed 's/\..*//' | sed 's/Server*//' | sort | tail -1)"
		;;

		"vmware photon")
			lsb_dist="photon"
			dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
		;;

		*)
			if command_exists lsb_release; then
				dist_version="$(lsb_release --codename | cut -f2)"
			fi
			if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
				dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
			fi
		;;
	esac

	if [ -z "$lsb_dist" -o -z "$dist_version" ]; then
		cat >&2 <<-EOF
		无法确定服务器系统版本信息。
		请联系脚本作者。
		EOF
		exit 1
	fi
}

install_deps() {
	ip_support_tuntap() {
		command_exists ip && ip tuntap >/dev/null 2>&1
	}
	case "$lsb_dist" in
		ubuntu|debian|raspbian)
			local did_apt_get_update=
			apt_get_update() {
				if [ -z "$did_apt_get_update" ]; then
					( set -x; sleep 3; apt-get update )
					did_apt_get_update=1
				fi
			}

			if ! command_exists wget; then
				apt_get_update
				( set -x; sleep 3; apt-get install -y -q wget ca-certificates )
			fi

			if ! command_exists ip; then
				apt_get_update
				( set -x; sleep 3; apt-get install -y -q iproute )
			fi

			if ! command_exists timeout; then
				apt_get_update
				( set -x; sleep 3; apt-get install -y -q coreutils )
			fi

			if ! command_exists iptables; then
				apt_get_update
				( set -x; sleep 3; apt-get install -y -q iptables )
			fi

			if ! ip_support_tuntap; then
				apt_get_update
				( set -x; sleep 3; apt-get install -y -q uml-utilities )
			fi
		;;
		fedora|centos|redhat|oraclelinux|photon)
			if [ "$lsb_dist" = "fedora" ] && [ "$dist_version" -ge "22" ]; then
				if ! command_exists wget; then
					( set -x; sleep 3; dnf -y -q install wget ca-certificates )
				fi

				if ! command_exists ip; then
					( set -x; sleep 3; dnf -y -q install iproute )
				fi

				if ! command_exists timeout; then
					( set -x; sleep 3; dnf -y -q install coreutils )
				fi

				if ! command_exists iptables; then
					( set -x; sleep 3; dnf -y -q install iptables )
				fi

				if ! ip_support_tuntap && ! command_exists tunctl; then
					( set -x; sleep 3; dnf -y -q install tunctl )
				fi
			elif [ "$lsb_dist" = "photon" ]; then
				if ! command_exists wget; then
					( set -x; sleep 3; tdnf -y install wget ca-certificates )
				fi

				if ! command_exists ip; then
					( set -x; sleep 3; tdnf -y install iproute )
				fi

				if ! command_exists timeout; then
					( set -x; sleep 3; tdnf -y install coreutils )
				fi

				if ! command_exists iptables; then
					( set -x; sleep 3; tdnf -y install iptables )
				fi

				if ! ip_support_tuntap && ! command_exists tunctl; then
					( set -x; sleep 3; tdnf -y install tunctl )
				fi
			else
				if ! command_exists wget; then
					( set -x; sleep 3; yum -y -q install wget ca-certificates )
				fi

				if ! command_exists ip; then
					( set -x; sleep 3; yum -y -q install iproute )
				fi

				if ! command_exists timeout; then
					( set -x; sleep 3; yum -y -q install coreutils )
				fi

				if ! command_exists iptables firewall-cmd; then
					( set -x; sleep 3; yum -y -q install iptables )
				fi

				if ! ip_support_tuntap && ! command_exists tunctl; then
					( set -x; sleep 3; yum -y -q install tunctl )
				fi
			fi
		;;
		*)
			cat >&2 <<-EOF
			暂时不支持当前系统：${lsb_dist} ${dist_version}
			EOF

			exit 1
		;;
	esac
}

check_nat_create() {
	if ( command_exists ip && ip tuntap >/dev/null 2>&1 ); then
		(
			set -x
			ip tuntap del dev lkl-tap-test mode tap >/dev/null 2>&1
			ip tuntap add dev lkl-tap-test mode tap
		)
	elif command_exists tunctl; then
		(
			set -x
			tunctl -d lkl-tap-test >/dev/null 2>&1
			tunctl -t lkl-tap-test
		)
	else
		cat >&2 <<-'EOF'
		无法找到已安装的 ip 命令(支持 tuntap) 或者 tunctl
		应该是脚本自动安装失败了。
		请手动安装 iproute 和 tunctl
		EOF
		exit 1
	fi

	if [ "$?" != "0" ]; then
		cat >&2 <<-'EOF'
		无法创建 NAT 网络。
		由于某些服务商的 VPS 无法创建 NAT 网络，
		所以不支持用此方法开启 BBR，安装脚本将会退出。
		EOF
		exit 1
	fi
}

download_file() {
	local url=$1
	local file=$2

	( set -x; wget -O "$file" --no-check-certificate "$url" )
	if [ "$?" != "0" ]; then
		cat >&2 <<-EOF
		一些文件下载失败！安装脚本需要能访问到 github.com，请检查服务器网络。
		注意: 一些国内服务器可能无法正常访问 github.com。
		EOF

		exit 1
	fi
}

install_haproxy() {
	(
		set -x
		mkdir -p "${HAPROXY_LKL_DIR}"/etc \
			"${HAPROXY_LKL_DIR}"/lib64 \
			"${HAPROXY_LKL_DIR}"/sbin
	)

	if ! grep -q '^haproxy:' '/etc/passwd'; then
		(
			set -x
			useradd -U -s '/usr/sbin/nologin' -d '/nonexistent' haproxy 2>/dev/null
		)
	fi

	local haproxy_bin="${HAPROXY_LKL_DIR}/sbin/haproxy"
	download_file "$HAPROXY_BIN_URL" "$haproxy_bin"
	chmod +x "$haproxy_bin"

	if ! ( $haproxy_bin -v 2>/dev/null | grep -q 'HA-Proxy' ); then
		cat >&2 <<-EOF
		HAproxy 可执行文件无法正常运行
		可能是 glibc 版本过低，或者文件不适用于你的系统。
		请联系脚本作者，寻求支持。
		EOF
		(
			set -x
			ldd --version
		)
		exit 1
	fi

	local haproxy_lkl_bin="${HAPROXY_LKL_DIR}/sbin/${SERVICE_NAME}"
	download_file "$HAPROXY_LKL_BIN_URL" "$haproxy_lkl_bin"

	sed -i -r "s#^HAPROXY_LKL_DIR=.*#HAPROXY_LKL_DIR='"${HAPROXY_LKL_DIR}"'#" \
		"$haproxy_lkl_bin"

	set_interface() {
		local has_vnet=0
		if command_exists ip; then
			ip -o link show | grep -q 'venet0'
			has_vnet=$?
		elif command_exists ifconfig; then
			ifconfig -s | grep -q 'venet0'
			has_vnet=$?
		fi

		if [ "$has_vnet" != 0 ]; then
			cat >&2 <<-EOF
			检测发现你的公网接口不是 venet0，需要你手动输入一下网络接口名称。
			我们会根据网络接口设置转发规则，如果网络接口名称设置不正确，
			外部网络将无法正常访问到内部服务端口。
			 * 网络接口是具有公网 IP 的接口名称。

			你可以从下面的信息中找到你的公网接口名称:
			EOF

			if command_exists ip; then
				ip addr show
			else
				ifconfig
			fi

			local input=
			while :
			do
				read -p "请输入你的网络接口名称(例如: eth0): " input
				echo
				if [ -n "$input" ]; then
					sed -i -r "s#^INTERFACE=.*#INTERFACE='"${input}"'#" "$haproxy_lkl_bin"
				else
					echo "输入信息不能为空，请重新输入！"
					continue
				fi

				break
			done
		fi
	}
	set_interface

	chmod +x "$haproxy_lkl_bin"

	local haproxy_lkl_startup_file=
	local haproxy_lkl_startup_file_url=

	if command_exists systemctl; then
		haproxy_lkl_startup_file="/lib/systemd/system/${SERVICE_NAME}.service"
		haproxy_lkl_startup_file_url="${HAPROXY_LKL_SYSTEMD_FILE_URL}"

		download_file "$haproxy_lkl_startup_file_url" "$haproxy_lkl_startup_file"
	elif command_exists service; then
		haproxy_lkl_startup_file="/etc/init.d/${SERVICE_NAME}"
		case "$lsb_dist" in
			ubuntu|debian|raspbian)
				haproxy_lkl_startup_file_url="${HAPROXY_LKL_SERVICE_FILE_DEBIAN_URL}"

				download_file "$haproxy_lkl_startup_file_url" "$haproxy_lkl_startup_file"
				chmod +x "$haproxy_lkl_startup_file"
			;;
			fedora|centos|redhat|oraclelinux|photon)
				haproxy_lkl_startup_file_url="${HAPROXY_LKL_SERVICE_FILE_REDHAT_URL}"

				download_file "$haproxy_lkl_startup_file_url" "$haproxy_lkl_startup_file"
				chmod +x "$haproxy_lkl_startup_file"
			;;
			*)
				echo "没有适合当前系统的服务启动脚本文件。"
				exit 1
			;;
		esac

	else
		cat >&2 <<-'EOF'
		当前服务器未安装 systemctl 或者 service 命令，无法配置服务。
		请先手动安装 systemd 或者 service 之后再运行脚本。
		EOF

		exit 1
	fi

	echo "$ACCELERATE_PORT" > "${HAPROXY_LKL_DIR}/etc/port-rules"
}

install_lkl_lib() {
	local lib_file="${HAPROXY_LKL_DIR}/lib64/liblkl-hijack.so"
	local retry=0
	download_lkl_lib() {
		download_file "$LKL_LIB_URL" "$lib_file"
		if command_exists md5sum; then
			(
				set -x
				echo "${LKL_LIB_MD5}  ${lib_file}" | md5sum -c
			)
			if [ "$?" != "0" ]; then
				if [ "$retry" -lt "3" ]; then
					echo "文件校验失败！3 秒后重新下载..."
					retry=`expr $retry + 1`
					sleep 3
					download_lkl_lib
				else
					cat >&2 <<-EOF
					Linux 内核文件校验失败。
					通常是网络原因造成文件下载不全。
					EOF
					exit 1
				fi
			fi
		fi
	}

	download_lkl_lib

	chmod +x "$lib_file"
}

enable_ip_forward() {
	local ip_forword="$(sysctl -n 'net.ipv4.ip_forward' 2>/dev/null)"
	if [ -z "$ip_forword" -o "$ip_forword" != "1" ]; then
		(
			set -x
			echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
			sysctl -p /etc/sysctl.conf 2>/dev/null
		)
	fi
}

setconfig() {
	is_port() {
		local port=$1
		expr $port + 1 >/dev/null 2>&1 && \
			[ "$port" -ge "1" -a "$port" -le "65535" ]
	}

	local input=

	if [ -z "$ACCELERATE_PORT" ] || ! is_port "$ACCELERATE_PORT"; then
		while :
		do
			read -p "请输入需要加速的端口 [1~65535]: " input
			echo
			if [ -n "$input" ] && is_port $input; then
					ACCELERATE_PORT="$input"
			else
				echo "输入有误, 请输入 1~65535 之间的数字!"
				continue
			fi
			break
		done
	fi

	cat >&2 <<-EOF
	---------------------------
	加速端口 = ${ACCELERATE_PORT}
	---------------------------
	EOF

}

is_running() {
	(
		set -x
		sleep 3
		timeout 2 bash -c "</dev/tcp/10.0.0.2/${ACCELERATE_PORT}" 2>/dev/null
	)
	return $?
}

enable_service() {
	if command_exists systemctl; then
		(
			set -x
			systemctl daemon-reload
			systemctl enable "${SERVICE_NAME}.service"
		)
	elif command_exists service; then
		case "$lsb_dist" in
			ubuntu|debian|raspbian)
				(
					set -x
					update-rc.d -f "${SERVICE_NAME}" defaults
				)
			;;
			fedora|centos|redhat|oraclelinux|photon)
				(
					set -x
					chkconfig --add "${SERVICE_NAME}"
					chkconfig "${SERVICE_NAME}" on
				)
			;;
		esac
	fi
}

start_service() {
	if command_exists systemctl; then
		(
			set -x
			sleep 3
			systemctl start "$SERVICE_NAME"
		)
	else
		(
			set -x
			sleep 3
			service "$SERVICE_NAME" start
		)
	fi

	if [ "$?" != "0" ] || ! is_running; then
		do_uninstall
		cat >&2 <<-EOF
		很遗憾，服务启动失败。
		你可以查看上面的日志来获取原因，
		或者，你可以到我们的群里反馈一下。
		EOF
		exit 1
	fi
}

end_install() {
	clear

	cat >&2 <<-EOF
	恭喜！BBR 安装完成并成功启动

	已加速的端口: ${ACCELERATE_PORT}

	你可以通过修改文件:
	    ${HAPROXY_LKL_DIR}/etc/port-rules

	来配置需要加速的端口或端口范围。
	EOF
	if command_exists systemctl; then

		cat >&2 <<-EOF

		请使用 systemctl {start|stop|restart} ${SERVICE_NAME}
		来 {开启|关闭|重启} 服务
		EOF
	else

		cat >&2 <<-EOF

		请使用 service ${SERVICE_NAME} {start|stop|restart}
		来 {开启|关闭|重启} 服务
		EOF
	fi
	cat >&2 <<-EOF

	服务已自动加入开机启动，请放心使用。

	享受加速的快感吧！
	EOF
  echo -e "\033[0;32m操作完成\033[0m"
  echo "按任意键继续..."
  read -n 1 -s -r -p ""
  echo ""
  clear
}

do_uninstall() {
	check_root
	get_os_info

	if command_exists systemctl; then
		systemctl stop "${SERVICE_NAME}.service" 2>/dev/null
		(
			set -x
			systemctl disable "${SERVICE_NAME}.service" 2>/dev/null
			rm -f "/lib/systemd/system/${SERVICE_NAME}.service"
		)
	elif command_exists service; then
		service "${SERVICE_NAME}" stop 2>/dev/null
		case "$lsb_dist" in
			ubuntu|debian|raspbian)
				(
					set -x
					update-rc.d -f "${SERVICE_NAME}" remove 2>/dev/null
				)
			;;
			fedora|centos|redhat|oraclelinux|photon)
				(
					set -x
					chkconfig "${SERVICE_NAME}" off 2>/dev/null
					chkconfig --del "${SERVICE_NAME}" 2>/dev/null
				)
			;;
		esac
		(
			set -x
			rm -f "/etc/init.d/${SERVICE_NAME}"
		)
	fi

	(
		set -x
		${HAPROXY_LKL_DIR}/sbin/${SERVICE_NAME} -c 2>/dev/null
		rm -rf "${HAPROXY_LKL_DIR}"
	)
}

do_install() {
	check_root
	check_ovz
	check_ldd
	check_arch
	get_os_info
	setconfig
	install_deps
	enable_ip_forward
	check_nat_create
	install_haproxy
	install_lkl_lib
	start_service
	enable_service
	end_install
}
action=${1:-"install"}
case "$action" in
	install|uninstall)
		do_${action}
	;;
	*)
		cat >&2 <<-EOF
		参数有误，请使用 $(basename $0) install|uninstall
		EOF
		exit 255
esac
}

# 函数：一键修改DNS1和DNS2
function set_dns() {
    read -p "请输入新的DNS服务器地址: " dns_server
    if [[ -f /etc/redhat-release ]]; then
        # CentOS
        echo "nameserver $dns_server" | sudo tee /etc/resolv.conf >/dev/null
        echo "DNS服务器已修改为 $dns_server"
    elif [[ -f /etc/lsb-release ]]; then
        # Ubuntu
        sudo sed -i "s/nameserver .*/nameserver $dns_server/" /etc/resolv.conf
        echo "DNS服务器已修改为 $dns_server"
    elif [[ -f /etc/debian_version ]]; then
        # Debian
        sudo sed -i "s/nameserver .*/nameserver $dns_server/" /etc/resolv.conf
        echo "DNS服务器已修改为 $dns_server"
    else
        echo "不支持的操作系统"
    fi
}
#********************************************************

# 分页大小，表示每页显示的菜单选项数量
PAGE_SIZE=10
# 当前页数
current_page=1
# 菜单选项数组
menu_options=(
    "✪ TCP加速一键安装管理脚本"
    "✪ Xray一键安装脚本}"
    "✪ v2ray一键安装脚本"
    "✪ Singbox - Reality一键安装脚本"
    "✪ Hysteria 2 一键安装脚本"
    "✪ shadowsocks/ss一键安装脚本"
    "✪ iptables 端口转发一键管理脚本增强版"
    "✪ gost 一键安装配置脚本"
    "✪ 一键修改root账户密码"
    "✪ 开启SSH登陆+替换ROOT密钥登陆"
    "✪ 修改SSH 端口默认22的端口"
    "✪ 一键修改DNS1和DNS2"
    "✪ Ipv4/6优先级调整"
    "✪ 自动防御cc"
    "✪ 换centos-7.x-yum源"
    "✪ VPS一键添加/删除swap脚本"
    "✪ 改变主机名"
    "✪ 咸蛋中转机面板 一键脚本"
    "✪ bbr加速用于 OpenVZ 服务器 一键安装脚本"
    "✪ 其他在开发......"
)


# 计算总页数
total_pages=$(((${#menu_options[@]} + PAGE_SIZE - 1) / PAGE_SIZE))

# 显示菜单
show_menu_page() {
    local start=$((PAGE_SIZE * (current_page - 1)))
    local end=$((start + PAGE_SIZE - 1))

    for ((i = start; i <= end; i++)); do
        if [ $i -lt ${#menu_options[@]} ]; then
            echo "$((i + 1)). ${menu_options[i]}"
        fi
    done
}


show_user_tips() {
    read -p "按 Enter 键继续..."
}

while true; do
    clear
    execute_once
    check_expiration
    show_expiration_info
    echo
    echo "***********************************************************************"
    echo "*  ✪  工具名称：（Linux脚本工具）      ✪ "
    echo "*  ✪  工具版本：v40.0.1  ✪      "
    echo "*  ✪       by ：网络跳越(hijk)       ✪        "
    echo "**********************************************************************"
    echo ""
    show_menu_page
    echo ""    
    echo "***********************************************************************"
    echo "  N: 下一页  B: 上一页  Q: 退出   第$current_page""页 / 总页数$total_pages"
    echo "***********************************************************************"
    echo
    read -p "请选择一个选项 (P/N/Q/ 不分大小写) : " choice

    case $choice in

    1)
       bbr
        show_user_tips
        ;;
    2)
        xrayx_install
        show_user_tips
        ;;
   3)
        v2rayy
        show_user_tips
        ;;

    4)
        REALITYy
        show_user_tips
        ;;
    5)
        Hysteria2
        show_user_tips
        ;;
    6)
        shadowsocksss
        show_user_tips
        ;;
    7)
        iptabless
        show_user_tips
        ;;
    8)
        setup_gost
        show_user_tips
        ;;
    9)
        adddhcp_root
        show_user_tips
        ;;
    10)
        addemotn_sshd
        show_user_tips
        ;;
    11)
        sessh_22
        show_user_tips
        ;;
    12)
        set_dns
        show_user_tips
        ;; 
    13)
       grouter_IPv4e
        show_user_tips
        ;;
    14)
        check_whiptailcc
        show_user_tips
        ;;
    15)
        do_CentOS7t
        show_user_tips
        ;;
    16)
        swap
        show_user_tips
        ;;
    17)
        xray22
        show_user_tips
        ;;
    18)
        xd
        show_user_tips
        ;;
    19)
        install_OpenVZ
        show_user_tips
        ;;
    [Nn])
        # 切换到下一页
        if [ $current_page -lt $total_pages ]; then
            current_page=$((current_page + 1))
        else
            echo
            echo "已经是最后一页了。"
            echo
            show_user_tips
        fi
        ;;
    [Bb])
        # 切换到上一页
        if [ $current_page -gt 1 ]; then
            current_page=$((current_page - 1))
        else
            echo
            echo "已经是第一页了。"
            echo
            show_user_tips
        fi
        ;;
    [Qq])
for i in {1..3}; do
    echo "========== 第 $i/3 次清屏 =========="
    timeout "$(gettext "清空屏幕")!"
    clear
    # 如果不是最后一次，显示提示信息
    if [[ $i -lt 3 ]]; then
        echo "屏幕已清空 ($i/3)"
        echo "1秒后开始下一次..."
        sleep 1
    fi
done

echo "完成！退出。"
clear
exit 0
        ;;
    *)
        echo "无效选项，请重新选择。"
        ;;
    esac
done





