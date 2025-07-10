#! /bin/bash 
# 网络跳越 
#production time：2024 03.14
#=====================检测vps机器=======================
#颜色
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
redd (){
    echo -e "\033[34m\033[01m$1\033[0m" 
}
yellow (){
    echo -e "\033[36m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[38m\033[01m$1\033[0m"
}
blu(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yllo (){
    echo -e "\033[33m\033[01m$1\033[0m"
} 
purp(){
    echo -e "\033[40m\033[01m$1\033[0m" 
}
pu(){
    echo -e "\033[31m\033[01m$1\033[0m" 
}
_red() {
    printf '\033[0;31;31m%b\033[0m' "$1"
}

_green() {
    printf '\033[0;31;32m%b\033[0m' "$1"
}
RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
red="\033[33m"      # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'     #
blu='\033[32m'      #

ScriptVersion=7.2.0.0
SCRIPTUPDATE=2024.03.15
  hostname=$(hostname)
  cpu_usage=$(top -bn1 | awk '/Cpu\(s\)/ {print $2}')
 mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')
  disk_info=$(df -h | awk '$NF=="/"{printf "%d/%dGB (%s)", $3,$2,$5}')
uptimes=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d 天 %d 时 %d 分\n",a,b,c)}' /proc/uptime )
ebug=0
show_ip=1
show_ipip=1
test_io=1
test_iops=0
full_ip=0
OPTS=$(getopt -n "$0" -o abcdfghij --long "debug,no-ip,no-ipip,no-io,full-ip,iops,delete" -- "$@")
eval set -- "$OPTS"
while true; do
  case "$1" in
    -a | --no-ip       ) show_ip=0       ; shift ;;
    -b | --no-ipip     ) show_ipip=0     ; shift ;;
    -c | --no-io       ) test_io=0       ; shift ;;
    -d | --debug       ) debug=1         ; shift ;;
    -f | --full-ip     ) full_ip=1       ; shift ;;
    -j | --iops        ) test_iops=1     ; shift ;;
         --delete      ) delete=1        ; shift ;;
    -- ) shift; break ;;
     * ) break ;;
  esac
done
black=$(tput setaf 0)   ; red=$(tput setaf 1)          ; green=$(tput setaf 2)   ; yellow=$(tput setaf 3);  bold=$(tput bold)
blue=$(tput setaf 4)    ; magenta=$(tput setaf 5)      ; cyan=$(tput setaf 6)    ; white=$(tput setaf 7) ;  normal=$(tput sgr0)
on_black=$(tput setab 0); on_red=$(tput setab 1)       ; on_green=$(tput setab 2); on_yellow=$(tput setab 3)
on_blue=$(tput setab 4) ; on_magenta=$(tput setab 5)   ; on_cyan=$(tput setab 6) ; on_white=$(tput setab 7)
shanshuo=$(tput blink)  ; wuguangbiao=$(tput civis)    ; guangbiao=$(tput cnorm) ; jiacu=${normal}${bold}
underline=$(tput smul)  ; reset_underline=$(tput rmul) ; dim=$(tput dim)
standout=$(tput smso)   ; reset_standout=$(tput rmso)  ; title=${standout}
baihuangse=${white}${on_yellow}; bailanse=${white}${on_blue} ; bailvse=${white}${on_green}
baiqingse=${white}${on_cyan}   ; baihongse=${white}${on_red} ; baizise=${white}${on_magenta}
heibaise=${black}${on_white}   ; heihuangse=${on_yellow}${black}
CW="${bold}${baihongse} ERROR ${jiacu}";ZY="${baihongse}${bold} ATTENTION ${jiacu}";JG="${baihongse}${bold} WARNING ${jiacu}"
_cancel() {
    rm -rf $HOME/.abench
    rm -f  test_file_*   1   $HOME/ipapi
    exit
}
trap _cancel INT QUIT TERM

mkdir -p $HOME/.abench
[[ $debug != 1 ]]
[[ $EUID = 0 ]]
source <(wget -qO- https://github.com/Aniverse/inexistence/raw/master/00.Installation/check-sys)
check_tcp_acc
echo -e "${bold}${normal}" ; hardware_check_1
seedbox_check
disk_size1=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem|docker|md[0-9]+/[a-z]*' | awk '{print $2}' ))
disk_size2=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem|docker|md[0-9]+/[a-z]*' | awk '{print $3}' ))
disk_total_size=$( calc_disk ${disk_size1[@]} )
disk_used_size=$( calc_disk ${disk_size2[@]} )
rm -f $HOME/.abench/disk.info
if [[ $EUID = 0 ]] && [[ "$virtual" == "No Virtualization Detected" ]]; then
    echo -n "${bold}"
    get_app_static smartctl
    disk_check_raid
else
    disk_check_no_root
fi
function sed_disk_num () {
    while read line ; do echo "$line" | sed -e "s|^disk-|  第 |g" -e "s|text \([0-9]\{1,\}\)|块硬盘           ${cyan}通电 \1 小时，型号|g" -e "s|$|&${jiacu}|g" ; done
}
function _show_disk_info () {
    if [[ $(cat $HOME/.abench/disk.info 2>/dev/null | sed -n '1p' | awk '{print $3}' | grep -Ev [A-Z] | grep -oE "[0-9]+") ]]; then
        disk_num=$( cat $HOME/.abench/disk.info 2>/dev/null | wc -l ) ; [[ $debug == 1 ]] && echo -e "disk_num=$disk_num"
        if [[ $disk_num == 1 ]]; then
            echo -e  "  硬盘信息              ${cyan}通电 $(cat $HOME/.abench/disk.info 2>/dev/null | sed -n '1p' | awk '{print $3}') 小时，型号 $(cat $HOME/.abench/disk.info 2>/dev/null | sed -n '1p' | awk '{print $4,$5,$6,$7}')${jiacu}"
        elif [[ $disk_num -ge 2 ]]; then
            cat $HOME/.abench/disk.info | sed_disk_num
        fi
    else 
        if [[ $disk_model_num == 1 ]]; then
            echo -e  "  硬盘型号              ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '1p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_1_num${jiacu}"
        elif [[ $disk_model_num -ge 2 ]]; then
            echo -e  "  第一种硬盘            ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '1p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_1_num${jiacu}"
            echo -e  "  第二种硬盘            ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '2p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_2_num${jiacu}"
        [[ $disk_model_num -ge 3 ]] &&
            echo -e  "  第三种硬盘            ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '3p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_3_num${jiacu}"
        [[ $disk_model_num -ge 4 ]] &&
            echo -e  "  第四种硬盘            ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '4p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_4_num${jiacu}"
        [[ $disk_model_num -ge 5 ]] &&
            echo -e  "  第五种硬盘            ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '5p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_5_num${jiacu}"
        [[ $disk_model_num -ge 6 ]] &&
            echo -e  "  第六种硬盘            ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '6p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_6_num${jiacu}"
        [[ $disk_model_num -ge 7 ]] &&
            echo -e  "  第七种硬盘            ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '7p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_7_num${jiacu}"
        [[ $disk_model_num -ge 8 ]] &&
            echo -e  "  第八种硬盘            ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '8p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_8_num${jiacu}"
        [[ $disk_model_num -ge 9 ]] &&
            echo -e  "  第九种硬盘            ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '9p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_9_num${jiacu}"
        [[ $disk_model_num -ge 10 ]] &&
            echo -e  "  第十种硬盘            ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '10p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_10_num${jiacu}"
        [[ $disk_model_num -ge 11 ]] &&
            echo -e  "  第十一种硬盘          ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '11p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_11_num${jiacu}"
        [[ $disk_model_num -ge 12 ]] &&
            echo -e  "  第十二种硬盘          ${cyan}$(cat $HOME/.abench/disk.info.2 2>/dev/null | sed -n '12p' | sed 's/$/                  /' | cut -c -27)${cyan} × $disk_model_12_num${jiacu}"
        [[ $disk_model_num -ge 13 ]] &&
            echo -e  "  暂时不支持 12 种以上硬盘的完整显示 …… ${jiacu}"
        fi
    fi
}
    cpu_aes=$(grep -i 'aes' /proc/cpuinfo)
    cpu_virt=$(grep -Ei 'vmx|svm' /proc/cpuinfo)
ipv4_check=$( (ping -4 -c 1 -W 4 ipv4.google.com >/dev/null 2>&1 && echo true) || ${ip_check_cmd} -4 icanhazip.com 2> /dev/null)
ipv6_check=$( (ping -6 -c 1 -W 4 ipv6.google.com >/dev/null 2>&1 && echo true) || ${ip_check_cmd} -6 icanhazip.com 2> /dev/null)
[[ -z "$ipv4_check" ]] && online="$(_red "\xe2\x9c\x97 Offline")" || online="$(_green "\xe2\x9c\x93 Online")"
[[ -z "$ipv6_check" ]] && online+=" / $(_red "\xe2\x9c\x97 Offline")" || online+=" / $(_green "\xe2\x9c\x93 Online")"
ipv4_chec() {
    serveripv4=$( ip route get 1 2>&1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p' )
    isInternalIpAddress "$serveripv4" && serveripv4=$( wget --no-check-certificate -4 -t1 -T6 -qO- v4.ipv6-test.com/api/myip.php )
    isValidIpAddress    "$serveripv4" || serveripv4=$( wget --no-check-certificate -4 -t1 -T6 -qO- ip.sb)
    isValidIpAddress    "$serveripv4" || serveripv4=$( wget --no-check-certificate -4 -t1 -T6 -qO- checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//' )
    isValidIpAddress    "$serveripv4" || serveripv4=$( wget --no-check-certificate -4 -t1 -T7 -qO- ipecho.net/plain )
    isValidIpAddress    "$serveripv4" || { echo "${bold}${red}${shanshuo}ERROR ${jiacu}${underline}Failed to detect your public IPv4 address, use internal address instead${normal}" ; serveripv4=$( ip route get 8.8.8.8 2>&1 | awk '{print $3}' ) ; }
    serveripv4_show=$serveripv4
}
ipv6_checks() {
    serveripv6=$( wget -t1 -T5 -qO- v6.ipv6-test.com/api/myip.php | grep -Eo "[0-9a-z:]+" | head -n1 )
    serveripv6_show=$serveripv6
}
[[ $show_ip   == 1 ]] && { ipv4_chec ; ipv6_checks ; }
[[ $show_ipip == 1 ]] && ip_ipinfo_aniverse

    org="$(wget -q -T10 -O- ipinfo.io/org)"
    city="$(wget -q -T10 -O- ipinfo.io/city)"
    country="$(wget -q -T10 -O- ipinfo.io/country)"
    region="$(wget -q -T10 -O- ipinfo.io/region)"
# 检测 IPv4 IPv6 信息
check_system_ip() {
  if [ -z "$VARIABLE_FILE" ]; then
    IP4=$(wget -4 -qO- --no-check-certificate --user-agent=Mozilla --tries=2 --timeout=3 http://ip-api.com/json/) &&
    WAN4=$(expr "$IP4" : '.*query\":[ ]*\"\([^"]*\).*') &&
    COUNTRY4=$(expr "$IP4" : '.*country\":[ ]*\"\([^"]*\).*') &&
    ASNORG4=$(expr "$IP4" : '.*isp\":[ ]*\"\([^"]*\).*') &&
    [[ "$L" = C && -n "$COUNTRY4" ]] && COUNTRY4=$(translate "$COUNTRY4")

    IP6=$(wget -6 -qO- --no-check-certificate --user-agent=Mozilla --tries=2 --timeout=3 https://api.ip.sb/geoip) &&
    WAN6=$(expr "$IP6" : '.*ip\":[ ]*\"\([^"]*\).*') &&
    COUNTRY6=$(expr "$IP6" : '.*country\":[ ]*\"\([^"]*\).*') &&
    ASNORG6=$(expr "$IP6" : '.*isp\":[ ]*\"\([^"]*\).*') &&
    [[ "$L" = C && -n "$COUNTRY6" ]] && COUNTRY6=$(translate "$COUNTRY6")
  fi
}
local_ipv4=$(curl $useNIC -4 -s --max-time 10 api64.ipify.org)
local_ipv4_asterisk=$(awk -F"." '{print $1"."$2".*.*"}' <<<"${local_ipv4}")
local_isp4=$(curl $useNIC -s -4 -A $UA_Browser --max-time 10 https://api.ip.sb/geoip/${local_ipv4} | grep organization | cut -f4 -d '"')
# 主界面
function _menu() {
    [[ $debug != 1 ]] && clear ; 
echo -e  " ${baizise}${bold}               网络跳越(sldm)                   ${jiacu} "
echo -e  "    主机名:             $hostname${jiacu}"
echo -e  "  CPU 型号              ${cyan}$CPUNum$cname${jiacu}"
echo -e  "  CPU 核心              ${cyan}合计 ${cpucores} 核心，${cputhreads} 线程${jiacu}"
if [[ -n "$cpu_aes" ]]; then
echo -e " AES-NI:              $(_green "\xe2\x9c\x93 Enabled")"
else
echo -e " AES-NI:              $(_red "\xe2\x9c\x97 Disabled")"
fi
if [ -n "$cpu_virt" ]; then
echo -e " VM-x/AMD-V           $(_green "\xe2\x9c\x93 Enabled")"
else
echo -e " VM-x/AMD-V           $(_red "\xe2\x9c\x97 Disabled")"
fi
echo -e  "  CPU 状态:             ${cyan}当前主频 ${freq} MHz${jiacu}"
echo -e  "  CPU 占用:             ${cyan}$cpu_usage %${jiacu}"
echo -e  "  内存大小:             ${cyan}$tram MB ($uram MB 已用)${jiacu}"
echo -e  "  内存占用:             ${cyan}$mem_info${jiacu}"
    [[ ! $swap == 0 ]] &&
echo -e  "  交换分区              ${cyan}$swap MB ($uswap MB 已用)${jiacu}"
    _show_disk_info | tee -a $HOME/.abench/_show_disk_info
    if [[ -s $HOME/.abench/_show_disk_info ]]; then
        [[ $debug != 1 ]] && rm -f $HOME/.abench/_show_disk_info
    fi
    SeedboxDisk="  "
    [[ $disk_num -ge 2 ]] && DiskNumDisplay="共 $disk_num 块硬盘，合计 " && SeedboxDiskTotalFlagOne="总" && SeedboxDisk=""
echo -e " ${SeedboxDiskTotalFlagOne}硬盘大小             ${SeedboxDisk}${cyan}${DiskNumDisplay}$disk_total_size GB${jiacu}"
            if [[ ! $Seedbox == Unknown ]] && [[ ! $EUID = 0 ]] && [[ ! $virtual == Docker ]]; then
echo -e  "  当前硬盘分区大小   ${cyan}${current_disk_size}B (共 ${current_disk_total_used}B 已用，其中你用了 ${current_disk_self_used}B)${jiacu}"
echo -e  "  共享盒子邻居数量      ${cyan}整台机器共 $neighbors_all_num 位邻居，其中同硬盘邻居 $neighbors_same_disk_num 位${jiacu}"
            fi
echo -e  "  服务器时间            ${cyan}$date${jiacu}"
echo -e  "  运行时间              ${cyan}$uptimes${jiacu}"
echo -e  "  系统负载              ${cyan}$load${jiacu}"
echo -e  "  虚拟化技术            ${cyan}$virtual${jiacu}"
            if [[ $show_ip == 1 ]]; then
echo -e  "  IPv4 地址             ${green}$local_ipv4_asterisk${jiacu}"
                [[ $serveripv6 ]] &&
echo -e  "  IPv6 地址             ${green}$serveripv6_show${jiacu}"
                [[ ! $Seedbox == Unknown ]] &&
echo -e  "  盒子域名              ${green}$serverfqdn${jiacu}"
            fi
            if [[ $show_ipip == 1 ]] && [[ -n $asnnnnn ]]; then
echo -e  "  运营商                ${green}$asnnnnn${jiacu}"
echo -e  "  地理位置              ${green}$country, $regionn, $cityyyy${jiacu}"
            fi
    [[ $show_ip == 1 || $show_ipip == 1 ]] 
echo -e  "  操作系统              ${green}$DISTRO $osversion $CODENAME ($arch)${jiacu}"
    [[ $running_kernel ]] &&
echo -e  "  系统内核              ${green}$running_kernel${jiacu}"
    [[ $tcp_c_name ]] &&
echo -e  "  TCP 加速              ${green}$tcp_c_name${jiacu}"
echo -e  "  IPv4/IPv6           ${green}$online${jiacu}"
echo -e  "  IP公司/AS编号         ${green}$org${jiacu}"
echo -e  "  国家                  ${green}$country${jiacu}"
echo -e  "  地区/城市             ${green}$city / ${green}$region${jiacu}"
echo -e  "  ${jiacu}当前脚本版本:         $ScriptVersion${normal}"
echo -e  "  ${jiacu}修改脚本时间:         $SCRIPTUPDATE${normal}"
    [[ $CODENAME == buster ]] && ls $HOME | grep -q images && echo -e 
}
check_system_ip
#=============
_menu #主界面
#=============