#!/bin/bash 
# 默认安装路径：/usr/local/bin/gost
# 配置文件路径：/etc/systemd/system/gost.service
# 如果需要更改配置，只需卸载并重新安装。

red='\033[0;31m'   # 错误信息的红色
green='\033[0;32m' # 成功信息的绿色
yellow='\033[0;33m' # 警告信息的黄色
plain='\033[0m'    # 默认颜色

install_gost(){
  # 更新包列表并安装依赖
  apt update || yum update
  apt install wget curl gzip jq -y || yum install epel-release wget curl jq gunzip -y

  # 获取最新版本的Gost
  version_tmp=$(curl https://api.github.com/repos/ginuerzh/gost/releases/latest  | jq .tag_name -r)
  version=${version_tmp:1}
  wget -O gost_${version}_linux_amd64.tar.gz https://github.com/ginuerzh/gost/releases/download/v${version}/gost_${version}_linux_amd64.tar.gz --no-check-certificate
  file=gost_${version}_linux_amd64.tar.gz
  tar -zxvf ${file}
  mv gost /usr/local/bin/gost
  chmod +x /usr/local/bin/gost

# 生成随机用户名、密码和端口的函数
  generate_random_user() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1
  }
  generate_random_pass() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1
  }
  generate_random_port() {
    shuf -i 10000-50000 -n 1
  }

  # 提示输入，留空则生成随机值
  read -p "请输入SOCKS5用户名（留空随机生成）:" user
  if [ -z "$user" ]; then
    user=$(generate_random_user)
  fi

  read -p "请输入SOCKS5密码（留空随机生成）:" passwd
  if [ -z "$passwd" ]; then
    passwd=$(generate_random_pass)
  fi

  read -p "请输入SOCKS5端口（留空随机生成）:" port
  if [ -z "$port" ]; then
    port=$(generate_random_port)
  fi
        
  # 创建systemd服务文件
  cat > /etc/systemd/system/gost.service << EOF
[Unit]
Description=Gost Proxy
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/gost -L ${user}:${passwd}@:${port} socks5://:${port}
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  # 重新加载systemd并启动服务
  systemctl daemon-reload
  systemctl start gost.service
  systemctl enable gost.service

  echo "安装完成"
  ip=$(curl ip.sb -4)
  echo "
  安装完成！
  链接信息
  IP:${ip}
  端口:${port}
  用户名:${user}
  密码:${passwd}
"  
}

uninstall(){
  # 停止并删除Gost服务和二进制文件
  systemctl stop gost.service
  rm -rf /usr/local/bin/gost
  rm -rf /etc/systemd/system/gost.service
  systemctl daemon-reload
  echo "卸载完成"
}

function info(){
  # 检查Gost是否已安装
  ls /etc/systemd/system/ | grep gost.service > /dev/null
  install_status=$?
  if [ $install_status == 0 ]
  then
     install_info="${green}已安装${plain}"
  else
     install_info="${red}未安装${plain}"
  fi
}

info

write_conf(){
  # 创建Gost配置文件
  cat > gost.conf << EOF
{
  "services": [
    {
      "name": "service-0",
      "addr": "${port}",
      "handler": {
        "type": "socks5",
        "auth": {
          "username": "${user}",
          "password": "${passwd}"
        }
      },
      "listener": {
        "type": "tcp"
      }
    }
  ]
}
EOF
}

# 显示菜单供用户选择
echo -e "${green} ******************** ${plain}"
echo -e "${green} 简单的SOCKS5安装脚本 ${plain}"
echo -e "${green} ******************** ${plain}"
echo -e "${green} 1. 安装SOCKS5 ${plain}"
echo -e "${green} 2. 卸载SOCKS5 ${plain}"
echo -e "${green} 安装状态: ${install_info}${plain}"
read  -p "请输入选项1或2:" xuanxiang
### 根据选择执行相应的函数 ###
case $xuanxiang in
  "1")
    install_gost
    ;;
  "2")
    uninstall
    ;;
  *)
    echo -e "${red} 输入有误，请重新输入 ${plain}"
    ;;
esac
