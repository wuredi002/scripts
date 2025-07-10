#!/bin/bash
echo "SSH开启密码、ROOT登录"
sshd_file="/etc/ssh/sshd_config"
cp -n $sshd_file /etc/ssh/sshd_config.bak
sed -i "s|^#\?PasswordAuthentication.*|PasswordAuthentication yes|" $sshd_file
sed -i "s|^#\?PermitRootLogin.*|PermitRootLogin yes|" $sshd_file
systemctl restart sshd;systemctl restart ssh;service sshd restart;service ssh restart
