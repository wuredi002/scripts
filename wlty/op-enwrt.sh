#!/bin/sh
check_bash_installed() {
  if [ -x "/bin/bash" ]; then
    echo "downloading common script......"
  else
    opkg update
    opkg install bash
  fi
}
check_bash_installed
wget -O Openwrt.sh  https://www.meng666.buzz/sld/Openwrt.sh && chmod u+x Openwrt.sh  && ./Openwrt.sh
