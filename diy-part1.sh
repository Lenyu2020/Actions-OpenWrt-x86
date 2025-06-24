#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
# Add a feed source
sed -i "/helloworld/d" "feeds.conf.default"
echo "src-git helloworld https://github.com/fw876/helloworld.git" >> "feeds.conf.default"
#
# Add passwall
echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> "feeds.conf.default"
#
mkdir -p files/usr/share
mkdir -p files/etc/
touch files/etc/lenyu_version
mkdir wget
touch wget/DISTRIB_REVISION1
touch wget/DISTRIB_REVISION3
touch files/usr/share/Check_Update.sh
touch files/usr/share/Lenyu-auto.sh
touch files/usr/share/Lenyu-pw.sh

# backup config
cat>>/etc/sysupgrade.conf<<-EOF
/etc/config/dhcp
/etc/config/sing-box
/etc/config/romupdate
/etc/config/passwall_show
/etc/config/passwall_server
/etc/config/passwall
/usr/share/passwall/rules/
/usr/share/singbox/
/usr/share/v2ray/
/etc/openclash/core/
/usr/bin/chinadns-ng
/usr/bin/sing-box
/usr/bin/hysteria
/usr/bin/xray
/usr/share/v2ray/geoip.dat
/usr/share/v2ray/geosite.dat
EOF


cat>rename.sh<<-\EOF
#!/bin/bash

# 清理旧文件
rm -rf bin/targets/x86/64/config.buildinfo
rm -rf bin/targets/x86/64/feeds.buildinfo
rm -rf bin/targets/x86/64/openwrt-x86-64-generic-kernel.bin
rm -rf bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.vmdk
rm -rf bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.vmdk
rm -rf bin/targets/x86/64/openwrt-x86-64-generic-squashfs-rootfs.img.gz
rm -rf bin/targets/x86/64/openwrt-x86-64-generic.manifest
rm -rf bin/targets/x86/64/sha256sums
rm -rf bin/targets/x86/64/version.buildinfo
sleep 2

# 读取版本号与内核补丁版本
rename_version=$(cat files/etc/lenyu_version)
str1=$(grep "KERNEL_PATCHVER:=" target/linux/x86/Makefile | cut -d '=' -f2)

# 动态获取补丁小版本
kernel_include_file="include/kernel-${str1}"
if [ -f "$kernel_include_file" ]; then
    ver=$(grep "LINUX_VERSION-${str1} =" "$kernel_include_file" | cut -d '.' -f3)
else
    ver=""
fi

# 定义源镜像和目标名称前缀
src_img=bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz
src_efi=bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz
base="openwrt_x86-64-${rename_version}_${str1}.${ver}"

# 重命名镜像，添加存在性检查
if [ -f "$src_img" ] && [ -f "$src_efi" ]; then
    mv "$src_img"   "bin/targets/x86/64/${base}_dev_Lenyu.img.gz"
    mv "$src_efi"   "bin/targets/x86/64/${base}_uefi-gpt_dev_Lenyu.img.gz"
else
    echo "镜像文件不存在，无法重命名：$src_img 或 $src_efi"
fi

# 生成版本列表
ls bin/targets/x86/64 | grep "gpt_dev_Lenyu.img" | cut -d '-' -f3 | cut -d '_' -f1-2 > wget/op_version1

# 生成 MD5 列表
ls -1 bin/targets/x86/64 > wget/open_dev_md5
dev_version=$(grep "_uefi-gpt_dev_Lenyu.img.gz" wget/open_dev_md5 | cut -d '-' -f3 | cut -d '_' -f1-2)
openwrt_dev=openwrt_x86-64-${dev_version}_dev_Lenyu.img.gz
openwrt_dev_uefi=openwrt_x86-64-${dev_version}_uefi-gpt_dev_Lenyu.img.gz

# 切换目录并生成 MD5 文件
cd bin/targets/x86/64 || exit 1
md5sum "$openwrt_dev" > openwrt_dev.md5
md5sum "$openwrt_dev_uefi" > openwrt_dev_uefi.md5

exit 0
EOF

cat>lenyu.sh<<-\EOOF
#!/bin/bash
lenyu_version="`date '+%y%m%d%H%M'`_dev_Len yu" 
echo $lenyu_version >  wget/DISTRIB_REVISION1 
echo $lenyu_version | cut -d _ -f 1 >  files/etc/lenyu_version  
#######
new_DISTRIB_REVISION=`cat  wget/DISTRIB_REVISION1`
grep "DISTRIB_REVISION="  package/lean/default-settings/files/zzz-default-settings | cut -d \' -f 2 >  wget/DISTRIB_REVISION3
old_DISTRIB_REVISION=`cat  wget/DISTRIB_REVISION3`
sed -i "s/${old_DISTRIB_REVISION}/${new_DISTRIB_REVISION}/"   package/lean/default-settings/files/zzz-default-settings
#
grep "Check_Update.sh"  package/lean/default-settings/files/zzz-default-settings
if [ $? != 0 ]; then
	sed -i 's/exit 0/ /'  package/lean/default-settings/files/zzz-default-settings
	cat>> package/lean/default-settings/files/zzz-default-settings<<-EOF
	sed -i '$ a alias lenyu="sh /usr/share/Check_Update.sh"' /etc/profile
	chmod 755 /etc/init.d/romupdate
	exit 0
	EOF
fi
grep "Lenyu-auto.sh"  package/lean/default-settings/files/zzz-default-settings
if [ $? != 0 ]; then
	sed -i 's/exit 0/ /'  package/lean/default-settings/files/zzz-default-settings
	cat>> package/lean/default-settings/files/zzz-default-settings<<-EOF
	sed -i '$ a alias lenyu-auto="sh /usr/share/Lenyu-auto.sh"' /etc/profile
	chmod 755 /etc/init.d/romupdate
	exit 0
	EOF
fi

grep "Lenyu-pw.sh"  package/lean/default-settings/files/zzz-default-settings
if [ $? != 0 ]; then
	sed -i 's/exit 0/ /'  package/lean/default-settings/files/zzz-default-settings
	cat>> package/lean/default-settings/files/zzz-default-settings<<-EOF
	sed -i '$ a alias lenyu-pw="sh /usr/share/Lenyu-pw.sh"' /etc/profile
	chmod 755 /etc/init.d/romupdate
	exit 0
	EOF
fi

grep "xray_backup"  package/lean/default-settings/files/zzz-default-settings
if [ $? != 0 ]; then
	sed -i 's/exit 0/ /'  package/lean/default-settings/files/zzz-default-settings
	cat>> package/lean/default-settings/files/zzz-default-settings<<-EOF
		cat> /etc/rc.local<<-EOFF
		# Put your custom commands here that should be executed once
		# the system init finished. By default this file does nothing.
		if [ -f "/etc/xray_backup/xray_backup" ]; then
		cp -f /etc/xray_backup/xray_backup /usr/bin/xray
		# chmod +x /usr/bin/xray
		# Check if the copy operation was successful
		  if [ $? -eq 0 ]; then
			 touch /tmp/xray_succ.log
		  fi
		rm -rf  /etc/xray_backup/xray_backup
		fi
		exit 0
		EOFF
		exit 0
	EOF
fi
EOOF

cat>files/usr/share/Check_Update.sh<<-\EOF
#!/bin/bash
# https://github.com/Lenyu2020/Actions-OpenWrt-x86
# Actions-OpenWrt-x86 By Lenyu 20210505
#path=$(dirname $(readlink -f $0))
# cd ${path}
#检测准备
if [ ! -f  "/etc/lenyu_version" ]; then
	echo
	echo -e "\033[31m 该脚本在非Lenyu固件上运行，为避免不必要的麻烦，准备退出… \033[0m"
	echo
	exit 0
fi
rm -f /tmp/cloud_version
# 获取固件云端版本号、内核版本号信息
current_version=`cat /etc/lenyu_version`
wget -qO- -t1 -T2 "https://api.github.com/repos/Lenyu2020/Actions-OpenWrt-x86/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g'  > /tmp/cloud_ts_version
if [ -s  "/tmp/cloud_ts_version" ]; then
	cloud_version=`cat /tmp/cloud_ts_version | cut -d _ -f 1`
	cloud_kernel=`cat /tmp/cloud_ts_version | cut -d _ -f 2`
	#固件下载地址
	new_version=`cat /tmp/cloud_ts_version`
	DEV_URL=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
	DEV_UEFI_URL=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
	openwrt_dev=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_dev.md5
	openwrt_dev_uefi=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_dev_uefi.md5
else
	echo "请检测网络或重试！"
	exit 1
fi
####
Firmware_Type="$(grep 'DISTRIB_ARCH=' /etc/openwrt_release | cut -d \' -f 2)"
echo $Firmware_Type > /etc/lenyu_firmware_type
echo
if [[ "$cloud_kernel" =~ "4.19" ]]; then
	echo
	echo -e "\033[31m 该脚本在Lenyu固件Sta版本上运行，目前只建议在Dev版本上运行，准备退出… \033[0m"
	echo
	exit 0
fi
#md5值验证，固件类型判断
if [ ! -d /sys/firmware/efi ];then
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_URL" -O /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
		wget -P /tmp "$openwrt_dev" -O /tmp/openwrt_dev.md5
		cd /tmp && md5sum -c openwrt_dev.md5
		if [ $? != 0 ]; then
      echo "您下载文件失败，请检查网络重试…"
      sleep 4
      exit
		fi
		Boot_type=logic
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
else
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_UEFI_URL" -O /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
		wget -P /tmp "$openwrt_dev_uefi" -O /tmp/openwrt_dev_uefi.md5
		cd /tmp && md5sum -c openwrt_dev_uefi.md5
		if [ $? != 0 ]; then
      echo "您下载文件失败，请检查网络重试…"
      sleep 4
      exit
		fi
		Boot_type=efi
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
fi

open_up()
{
echo
clear
read -n 1 -p  " 您是否要保留配置升级，保留选择Y,否则选N:" num1
echo
case $num1 in
	Y|y)
	echo
  echo -e "\033[32m >>>正在准备保留配置升级，请稍后，等待系统重启…-> \033[0m"
	echo
	sleep 3
	if [ ! -d /sys/firmware/efi ];then
		sysupgrade /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz		
	else
		sysupgrade /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
	fi
    ;;
    n|N)
    echo
    echo -e "\033[32m >>>正在准备不保留配置升级，请稍后，等待系统重启…-> \033[0m"
    echo
    sleep 3
	if [ ! -d /sys/firmware/efi ];then
		sysupgrade -n  /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
	else
		sysupgrade -n  /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
	fi
    ;;
    *)
	  echo
    echo -e "\033[31m err：只能选择Y/N\033[0m"
	  echo
    read -n 1 -p  "请回车继续…"
	  echo
	  open_up
esac
}

open_op()
{
echo
read -n 1 -p  " 您确定要升级吗，升级选择Y,否则选N:" num1
echo
case $num1 in
	Y|y)
	  open_up
    ;;
  n|N)
    echo
    echo -e "\033[31m >>>您已选择退出固件升级，已经终止脚本…-> \033[0m"
    echo
    exit 1
    ;;
  *)
    echo
    echo -e "\033[31m err：只能选择Y/N\033[0m"
    echo
    read -n 1 -p  "请回车继续…"
    echo
    open_op
esac
}
open_op
exit 0
EOF

cat>files/usr/share/Lenyu-auto.sh<<-\EOF
#!/bin/bash
# https://github.com/Lenyu2020/Actions-OpenWrt-x86
# Actions-OpenWrt-x86 By Lenyu 20210505
#path=$(dirname $(readlink -f $0))
# cd ${path}
#检测准备
if [ ! -f  "/etc/lenyu_version" ]; then
	echo
	echo -e "\033[31m 该脚本在非Lenyu固件上运行，为避免不必要的麻烦，准备退出… \033[0m"
	echo
	exit 0
fi
rm -f /tmp/cloud_version

# 备份backup-passwall中的xray文件
if [ ! -d "/etc/xray_backup" ]; then
    mkdir /etc/xray_backup
fi
cp -f /usr/bin/xray /etc/xray_backup/xray_backup

# 获取固件云端版本号、内核版本号信息
current_version=`cat /etc/lenyu_version`
wget -qO- -t1 -T2 "https://api.github.com/repos/Lenyu2020/Actions-OpenWrt-x86/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g'  > /tmp/cloud_ts_version
if [ -s  "/tmp/cloud_ts_version" ]; then
	cloud_version=`cat /tmp/cloud_ts_version | cut -d _ -f 1`
	cloud_kernel=`cat /tmp/cloud_ts_version | cut -d _ -f 2`
	#固件下载地址
	new_version=`cat /tmp/cloud_ts_version`
	DEV_URL=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
	DEV_UEFI_URL=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
	openwrt_dev=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_dev.md5
	openwrt_dev_uefi=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_dev_uefi.md5
else
	echo "请检测网络或重试！"
	exit 1
fi
####
Firmware_Type="$(grep 'DISTRIB_ARCH=' /etc/openwrt_release | cut -d \' -f 2)"
echo $Firmware_Type > /etc/lenyu_firmware_type
echo
#md5值验证，固件类型判断
if [ ! -d /sys/firmware/efi ];then
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_URL" -O /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
		wget -P /tmp "$openwrt_dev" -O /tmp/openwrt_dev.md5
		cd /tmp && md5sum -c openwrt_dev.md5
		if [ $? != 0 ]; then
		  echo "您下载文件失败，请检查网络重试…"
		  sleep 4
		  exit
		fi
		sysupgrade /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
else
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_UEFI_URL" -O /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
		wget -P /tmp "$openwrt_dev_uefi" -O /tmp/openwrt_dev_uefi.md5
		cd /tmp && md5sum -c openwrt_dev_uefi.md5
		if [ $? != 0 ]; then
			echo "您下载文件失败，请检查网络重试…"
			sleep 1
			exit
		fi
		sysupgrade /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
fi

exit 0
EOF

cat>files/usr/share/Lenyu-pw.sh<<-\EOF
#!/bin/sh
# Define variables
TEMP_DIR="/tmp/test"
PSVERSION_FILE="/usr/share/psversion"
UNZIP_URL="https://downloads.openwrt.org/releases/packages-23.05/x86_64/packages/unzip_6.0-8_x86_64.ipk"
UNZIP_PACKAGE="unzip_6.0-8_x86_64.ipk"
RED='\033[0;31m'    # Red color
BLUE='\033[0;34m'   # Blue color
ORANGE='\033[0;33m' # Orange color
NC='\033[0m'        # No Color (reset)

# Echo message in red color
echo_red() {
  echo -e "${RED}$1${NC}"
}

# Echo message in blue color
echo_blue() {
  echo -e "${BLUE}$1${NC}"
}

# Echo message in orange color
echo_orange() {
  echo -e "${ORANGE}$1${NC}"
}

# Preparing for update (blue message)
echo_blue "正在做更新前的准备工作..."
# 检查 unzip 是否已安装
if opkg list-installed | grep -q unzip; then
    echo "unzip 已经安装，跳过安装步骤。"
else
    # 下载 unzip 包
    echo "开始下载 unzip 包..."
    wget -q --show-progress "$UNZIP_URL" -O "$UNZIP_PACKAGE"

    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        echo "下载成功，开始安装 unzip 包..."
        opkg install "$UNZIP_PACKAGE"
        
        # 检查安装是否成功
        if [ $? -eq 0 ]; then
            echo "unzip 安装成功！"
        else
            echo "unzip 安装失败！"
        fi
    else
        echo "unzip 下载失败！"
    fi
fi

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Get the latest release information from GitHub
latest_release=$(curl -s https://api.github.com/repos/xiaorouji/openwrt-passwall/releases/latest)

# Extract version number from GitHub release (例如 "25.3.9-1")
version=$(echo "$latest_release" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')


# Extract download URLs
luci_app_passwall_url=$(echo "$latest_release" | grep -o '"browser_download_url": "[^"]*luci-24.10_luci-app-passwall_[^"]*"' | sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/')
luci_i18n_passwall_url=$(echo "$latest_release" | grep -o '"browser_download_url": "[^"]*luci-24.10_luci-i18n-passwall-zh-cn_[^"]*"' | sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/')

# 获取文件名（例如 luci-24.10_luci-app-passwall_25.3.9-r1_all.ipk）
app_file=$(basename "$luci_app_passwall_url")
i18n_file=$(basename "$luci_i18n_passwall_url")

# 从 app_file 中提取版本号部分，即 "25.3.9-r1"
version2410=$(echo "$app_file" | sed -E 's/^luci-24\.10_luci-app-passwall_([^_]+)_all\.ipk$/\1/')
echo_blue "最新云端版本号：$version2410"

# 将当前安装的版本写入 psversion 文件
opkg list-installed | grep luci-app-passwall | awk '{print $3}' > "$PSVERSION_FILE"
installed_version=$(cat "$PSVERSION_FILE" 2>/dev/null)
echo_blue "最新本地版本号：$installed_version"

# 检查版本是否已经是最新的，比较时使用 version2410 变量
if [ "$installed_version" = "$version2410" ]; then
  echo_red "已经是最新版本，还更新个鸡毛啊！"
  exit 0
fi

# 如果版本不一致，提示用户确认（10秒倒计时，默认 y）
echo_orange "你即将更新 passwall 为最新版本：$version2410，确定更新吗？(y/n, 回车默认y，10秒后自动执行y)"
read -t 10 -r confirmation
confirmation=${confirmation:-y}

if [ "$confirmation" != "y" ]; then
  echo_blue "已取消更新。"
  exit 0
fi

# 用户确认后继续更新
echo_blue "新版本可用，开始更新..."

# 下载文件到临时目录（保持原文件名）
wget -O "$TEMP_DIR/$app_file" "$luci_app_passwall_url"
wget -O "$TEMP_DIR/$i18n_file" "$luci_i18n_passwall_url"
sleep 5
echo "下载完成:"
echo "$TEMP_DIR/$app_file"
echo "$TEMP_DIR/$i18n_file"

# 安装下载的 IPK 包
sleep 1
/etc/init.d/passwall stop
opkg install "$TEMP_DIR/$app_file" --force-overwrite
opkg install "$TEMP_DIR/$i18n_file" --force-overwrite

# 重启 passwall 服务
/etc/init.d/passwall restart

# 将新版本号（version2410）写入 psversion 文件
echo "$version2410" > "$PSVERSION_FILE"

echo_blue "插件已安装并且 passwall 服务已重启。"

# 清理临时目录
rm -rf "$TEMP_DIR"

exit 0


EOF


