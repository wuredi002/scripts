#!/bin/bash
# 软路由通用脚本————项目的目标是把非iStoreOS的OpenWrt,轻松的变成iStoreOS的风格,比如斐讯N1是没有iStoreOS固件的
# 当你习惯使用某个固件的时候，同时又想具备iStoreOS的UI风格和应用商店，此时用它最合适。
# 比如R2S官方FriendlyELEC固件集成了大量的USB无线网卡驱动,用到无线发射ap的小伙伴就可以用这个脚本来丰富官方固件的功能，又保留了无线网卡驱动。
# 它是一个简单的调试工具 是锦上添花的东西，并非大而全的工具。并且这套脚本不安装敏感插件。
# 网络跳越(sldm) 

# 全局变量来标记是否已经执行一次性操作
executed_once=0
# 定义只执行一次的操作
execute_once() {
    if [ $executed_once -eq 0 ]; then
        remove_some_not_found_source
        executed_once=1
    fi
}

# 删除系统里的无效源
remove_some_not_found_source() {
    # 删除Flippy N1固件里的无效源404
    sed -i '/src\/gz openwrt_core https:\/\/mirrors.cloud.tencent.com\/lede\/snapshots\/targets\/armvirt\/64\/packages/d' /etc/opkg/distfeeds.conf
    sed -i '/src\/gz openwrt_small https:\/\/mirrors.cloud.tencent.com\/lede\/snapshots\/packages\/aarch64_generic\/small/d' /etc/opkg/distfeeds.conf
    sed -i '/src\/gz openwrt_kenzo https:\/\/mirrors.cloud.tencent.com\/lede\/snapshots\/packages\/aarch64_generic\/kenzo/d' /etc/opkg/distfeeds.conf
    # 删除FriendlyWrt系统里的无效的本地路径引用
    sed -i '/src\/gz friendlywrt_packages file:\/\/opt\/packages/d' /etc/opkg/distfeeds.conf
}

#设置wan口可访问webui,这一步是为了方便软路由连接wan口一根网线的时候，调试方便，
#如果你为了绝对安全，你可以在:网络——防火墙 将wan口设置为拒绝
set_firewall_wan_open() {
    ## 设置防火墙wan 打开
    uci set firewall.@zone[1].input='ACCEPT'
    uci commit firewall
    /etc/init.d/firewall reload
}

#设置wan口可访问ttyd终端
#这一步是为了方便软路由连接wan口一根网线的时候，可以顺利的进入ttyd终端。
set_ttyd_wan_enble() {
    # 删除 option interface '@lan'
    uci delete ttyd.@ttyd[0].interface
    uci commit
    /etc/init.d/firewall reload
}

# 判断 是否为is_kiddin9_os
is_kiddin9_os() {
    # 使用 grep 命令来搜索文件中是否包含 op.supes.top
    if grep -q "op.supes.top" /etc/opkg/distfeeds.conf; then
        return 0
    else
        return 1
    fi
}

#设置时区、语言、主题
set_lang_zone_argone() {
    uci set system.@system[0].zonename='Asia/Shanghai'
    uci set system.@system[0].timezone='CST-8'
    uci commit system
    /etc/init.d/system reload
    #判断如果是supes的固件
    if is_kiddin9_os; then
        echo "this is the op.supes.top firmware,no need to argone theme"
    else
        ##设置Argone 紫色主题 并且 设置第三方软件源
        setup_software_source 1

        opkg install luci-app-${skin}-config
        uci set luci.main.mediaurlbase='/luci-static/'${skin}
        # 默认设置为简体中文
        uci set luci.main.lang='zh_cn'
        uci commit
    fi
}

#判断是否为x86软路由
is_x86_64_router() {
    DISTRIB_ARCH=$(cat /etc/openwrt_release | grep "DISTRIB_ARCH" | cut -d "'" -f 2)
    if [ "$DISTRIB_ARCH" = "x86_64" ]; then
        return 0
    else
        return 1
    fi
}

## 安装应用商店
install_istore() {
    if is_iStoreOS; then
        echo "您的系统本来就是iStoreOS,已经内置iStore应用商店"
    else
        echo "正在安装iStore应用商店...."
        #设置主题（包含设置第三方软件源 setup_software_source 1）
        set_lang_zone_argone
        #Fix N1 安装不了luci-app-store的问题
        opkg remove git-lfs
        #根据软件源安装
        opkg install luci-app-store
        opkg install quickstart
        opkg install luci-app-quickstart --force-depends
        #如果首页安装成功
        if opkg list-installed | grep -q "luci-app-quickstart"; then
            #为了首页的完整性,这里要安装易有云的本地文件管理器
            sh -c "$(wget --no-check-certificate -qO- http://fw.koolcenter.com/binary/LinkEase/Openwrt/install_linkease.sh)"
            #为了首页的风格完全和iStoreOS一致,这里修改了名称
            uci set system.@system[0].hostname='iStoreOS'
            uci commit system
            /etc/init.d/system reload
            # 若已安装iStore商店则在概览中追加iStore字样
            if is_x86_64_router; then
                extra_info="with iStoreOS Style"
                current_revision=$(grep "DISTRIB_REVISION" /etc/openwrt_release | cut -d "'" -f 2)
                # 检查是否已包含extra_info
                if [[ $current_revision != *"$extra_info"* ]]; then
                    new_revision="${current_revision} ${extra_info}"
                    sed -i "s/DISTRIB_REVISION=.*$/DISTRIB_REVISION='$new_revision'/" /etc/openwrt_release
                fi
            else
                if ! grep -q " like iStoreOS" /tmp/sysinfo/model; then
                    sed -i '1s/$/ like iStoreOS/' /tmp/sysinfo/model
                fi
            fi
        else
            echo "首页安装失败,要不你换个新版本固件试试?"
            cat /etc/openwrt_release
        fi
        #还原软件源
        setup_software_source 0

    fi
}

# 判断OpenWrt系统的ARM架构并设置不同的软件源
set_packages_by_arch() {
    # 获取返回结果的总行数
    local total_lines=$(opkg print-architecture | wc -l)
    local architecture=""
    local source="https://op.dllkids.xyz/packages/"
    #先清空追加iStore软件源
    echo "src/gz is_store https://istore.linkease.com/repo/all/store" >/etc/opkg/customfeeds.conf
    if [ "$total_lines" -eq 4 ]; then
        # 如果总行数为四行，则提取第四行的架构信息
        architecture=$(opkg print-architecture | awk 'NR==4{print $2}')
        echo "No.4 architecture info===="${architecture}
        echo "src/gz custom_dllkids "${source}${architecture} >>/etc/opkg/customfeeds.conf
    elif [ "$total_lines" -eq 3 ]; then
        # 如果总行数为三行，则提取第三行的架构信息
        architecture=$(opkg print-architecture | awk 'NR==3{print $2}')
        echo "No.3 architecture info===="${architecture}
        echo "src/gz custom_dllkids "${source}${architecture} >>/etc/opkg/customfeeds.conf
    else
        echo "未知的返回结果行数: $total_lines"
    fi
}

# 设置第三方软件源
setup_software_source() {
    ## 传入0和1 分别代表原始和第三方软件源
    if [ "$1" -eq 0 ]; then
        echo "# add your custom package feeds here" >/etc/opkg/customfeeds.conf
        ## 还原软件源之后，要添加签名
        add_check_signature_option
        # 还原软件源之后更新
        opkg update
    elif [ "$1" -eq 1 ]; then
        # 传入1 代表设置第三方软件源 先要删掉签名
        remove_check_signature_option
        # 检查是否是x86_64路由器
        if is_x86_64_router; then
            #清空后添加
            echo "src/gz is_store https://istore.linkease.com/repo/all/store" >/etc/opkg/customfeeds.conf
            echo "src/gz dllkids https://op.dllkids.xyz/packages/x86_64" >>/etc/opkg/customfeeds.conf
        else
            # 根据架构设置arm的软件源
            set_packages_by_arch
        fi
        # 设置第三方源后要更新
        opkg update
    else
        echo "Invalid option. Please provide 0 or 1."
    fi
}

# 添加主机名映射(解决安卓原生TV首次连不上wifi的问题)
add_dhcp_domain() {
    local domain_name="time.android.com"
    local domain_ip="203.107.6.88"
    # 检查是否存在相同的域名记录
    existing_records=$(uci show dhcp | grep "dhcp.@domain\[[0-9]\+\].name='$domain_name'")
    if [ -z "$existing_records" ]; then
        # 添加新的域名记录
        uci add dhcp domain
        uci set "dhcp.@domain[-1].name=$domain_name"
        uci set "dhcp.@domain[-1].ip=$domain_ip"
        uci commit dhcp
        echo
        echo "已添加新的域名记录"
    else
        echo "相同的域名记录已存在，无需重复添加"
    fi
    echo -e "\n"
    echo -e "time.android.com    203.107.6.88 "
}

# 添加emotn域名
add_emotn_domain() {
    # 检查 passwall 的代理域名文件是否存在
    if [ -f "/usr/share/passwall/rules/proxy_host" ]; then
        sed -i "s/keeflys.com//g" "/usr/share/passwall/rules/proxy_host"
        echo -n "keeflys.com" | tee -a /usr/share/passwall/rules/proxy_host
        echo "在passwall代理域名中 添加成功!"
    else
        echo "在passwall代理域名中 添加失败! 请确保 passwall 已安装"
    fi
    # 检查 SSRP 的黑名单文件是否存在
    if [ -f "/etc/ssrplus/black.list" ]; then
        sed -i "s/keeflys.com//g" "/etc/ssrplus/black.list"
        echo -n "keeflys.com" | tee -a /etc/ssrplus/black.list
        echo "添加成功!"
    else
        echo "添加失败! 请确保 SSRP 已安装"
    fi
    echo -e "\n\n"
}

#装机必备
set_system_kits() {
    if is_iStoreOS; then
        echo "系统是iStoreOS"
    else
        echo "正在安装iStore应用商店...."
        install_istore
    fi
    if opkg list-installed | grep -q "luci-app-store"; then
        echo "正在使用iStore商店安装必备系统工具...."
        #升级iStore应用商店
        is-opkg do_self_upgrade
        # 安装 关机、ddns内网穿透、系统便利工具、定时设置
        is-opkg install 'app-meta-poweroff'
        is-opkg install 'app-meta-ddnsto'
        is-opkg install 'app-meta-systools'
        is-opkg install 'app-meta-autotimeset'
    else
        echo "应用商店没有安装成功,不兼容适配,要不换一个新版固件吧!"
        cat /etc/openwrt_release
    fi

}

##获取软路由型号信息
get_router_name() {
    if is_x86_64_router; then
        model_name=$(grep "model name" /proc/cpuinfo | head -n 1 | awk -F: '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
        echo "$model_name"
    else
        model_info=$(cat /tmp/sysinfo/model)
        echo "$model_info"
    fi
}

# 判断系统是否为iStoreOS
is_iStoreOS() {
    # 提取DISTRIB_ID的值，去掉单引号并赋给变量
    DISTRIB_ID=$(cat /etc/openwrt_release | grep "DISTRIB_ID" | cut -d "'" -f 2)
    # 检查DISTRIB_ID的值是否等于'iStoreOS'
    if [ "$DISTRIB_ID" = "iStoreOS" ]; then
        return 0 # true
    else
        return 1 # false
    fi
}

# 检查是否安装了 whiptail
check_whiptail_installed() {
    if [ -e /usr/bin/whiptail ]; then
        return 0
    else
        return 1
    fi
}

#定义一个通用的Dialog
show_whiptail_dialog() {
    #判断是否具备whiptail dialog组件
    if check_whiptail_installed; then
        echo "whiptail has installed"
    else
        opkg update
        opkg install whiptail
    fi
    local title="$1"
    local message="$2"
    local function_definition="$3"
    whiptail --title "$title" --yesno "$message" 15 60 --yes-button "是" --no-button "否"
    if [ $? -eq 0 ]; then
        eval "$function_definition"
    else
        echo "用户选择了 '否'"
    fi
}

# 执行重启操作
do_reboot() {
    reboot
}
# 关机
do_poweroff() {
    poweroff
}

#提示用户要重启
show_reboot_tips() {
    reboot_code='do_reboot'
    show_whiptail_dialog "软路由重启提醒" "           您是否要重启软路由?" "$reboot_code"
}

#提示用户要关机
show_poweroff_tips() {
    poweroff_code='do_poweroff'
    show_whiptail_dialog "软路由重启提醒" "           您是否要关闭软路由?" "$poweroff_code"
}

#查看网口信息
show_all_interface() {
    # 获取所有网络接口的名称
    all_interfaces=$(ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d')

    # 遍历所有接口，并查找有IP地址的接口
    for interface in $all_interfaces; do
        ip_address=$(ifconfig $interface | awk '/inet addr/{print substr($2,6)}')

        if [ ! -z "$ip_address" ]; then
            # 排除docker0
            if [ "$interface" != "docker0" ]; then
                # 以"eth"开头的接口重命名为"WAN"
                if [[ "$interface" == eth* ]]; then
                    interface="WAN"
                fi

                if [ "$interface" = "br-lan" ]; then
                    interface="LAN"
                elif [[ "$interface" == eth* ]]; then
                    interface="WAN"
                fi
                echo "---------$interface 口的IP地址是: $ip_address"
            fi
        fi
    done
}

#提示用户要重启后生效
install_wireguard() {
    remove_check_signature_option
    setup_software_source 1
    opkg update
    opkg install luci-app-wireguard
    setup_software_source 0
    echo "已安装, 重启后 生效"
}

# 去广告
install_adguardhome() {
    remove_check_signature_option
    setup_software_source 1
    opkg update
    opkg install luci-app-adguardhome
    setup_software_source 0
}

## 去除opkg签名
remove_check_signature_option() {
    local opkg_conf="/etc/opkg.conf"
    sed -i '/option check_signature/d' "$opkg_conf"
}

## 添加opkg签名
add_check_signature_option() {
    local opkg_conf="/etc/opkg.conf"
    echo "option check_signature 1" >>"$opkg_conf"
}

skin="Argon"

#********************************************************


# 分页大小，表示每页显示的菜单选项数量
PAGE_SIZE=20
# 当前页数
current_page=1
# 菜单选项数组
menu_options=(
    "一键安装iStoreOS风格化(x86_64、PHICOMM N1)"
    "一键安装iStoreOS风格化(FriendlyWrt R2S etc)"
    "一键卸载Argon主题"
    "添加主机名映射(解决安卓原生TV首次连不上wifi的问题)"
    "添加Emotn Store域名(解决打开emotn弹框问题)"
    "设置软路由WAN口可访问WebUI"
    "设置WAN口可访问TTYD终端"
    "查看当前WAN口IP地址"
    "安装系统调试必备工具"
    "安装WireGuard"
    "安装AdGuard Home"
    "等待开发12"
    "等待开发13"
    "等待开发14"
    "等待开发15"
    "等待开发16"
    #"等待开发18"
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

is_FriendlyWrt() {
    local router_name=$(get_router_name)
    if echo "$router_name" | grep -qiE "Friendly|NanoPi"; then
        return 0 # true
    else
        return 1
    fi
}

is_Phicomm_N1() {
    local router_name=$(get_router_name)
    if echo "$router_name" | grep -qiE "Phicomm N1"; then
        return 0 # true
    else
        return 1
    fi
}

while true; do
    clear
    execute_once
    echo "***********************************************************************"
    echo "*      软路由通用工具箱(for Openwrt工具 ) v20.0        "
    echo "*      自动识别CPU架构 x86_64/Arm 均可使用         "
    echo "*      by 网络跳越(sldm)        "
    echo "**********************************************************************"
    echo
    echo "*      当前的软路由型号: $(get_router_name)"
    echo
    echo "**********************************************************************"
    echo
    show_menu_page
    echo
    echo "***********************************************************************"
    echo "N: 下一页  B: 上一页  Q: 退出  R: 重启  第$current_page""页 / 总页数$total_pages"
    echo "***********************************************************************"
    echo
    read -p "请选择一个选项 (N/B/Q/R 不分大小写) : " choice

    case $choice in

    1)
        #安装iStore和首页风格(x86、N1)
        if is_FriendlyWrt; then
            echo "您应该选择 选项2,按Enter键后,请重新选择 选项2"
        else
            skin="argone"
            install_istore
        fi
        show_user_tips
        ;;
    2)
        #安装iStore和首页风格(R2S-FriendlyWrt)
        if is_x86_64_router || is_Phicomm_N1; then
            echo "您应该选择选项1,按Enter键后,请重新选择 选项1"
        else
            skin="argon"
            install_istore
        fi
        show_user_tips
        ;;
    3)
        #卸载argon主题
        echo
        opkg remove luci-theme-argone
        opkg remove luci-theme-argon
        opkg remove luci-app-argone-config
        opkg remove luci-app-argon-config
        [ -f "/usr/lib/lua/luci/controller/argone-config.lua" ] && rm "/usr/lib/lua/luci/controller/argone-config.lua"
        show_user_tips
        ;;

    4)
        #解决安卓原生TV首次连不上wifi的问题
        add_dhcp_domain
        show_user_tips
        ;;
    5)
        #添加emotn域名防止弹框
        add_emotn_domain
        show_user_tips
        ;;
    6)
        echo
        #软路由WAN口可访问后台网页
        set_firewall_wan_open
        show_user_tips
        ;;
    7)
        echo
        #设置wan口可访问终端ttyd
        set_ttyd_wan_enble
        show_user_tips
        ;;
    8)
        echo
        #查看当前WAN口IP地址
        show_all_interface
        show_user_tips
        ;;
    9)
        echo
        #安装系统必备插件
        set_system_kits
        show_user_tips
        ;;
    10)
        echo
        #安装WireGuard
        install_wireguard
        show_user_tips
        show_reboot_tips
        ;;
    11)
        echo
        #安装adguardhome
        install_adguardhome
        show_user_tips
        ;;
    12)
        echo
        #安装搭建科学上网工具
        VPN
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
        echo
        echo "您已退出,欢迎下次再来"
        exit 0
        ;;
    [Rr])
        echo
        show_reboot_tips
        ;;
    *)
        echo "无效选项，请重新选择。"
        ;;
    esac
done
