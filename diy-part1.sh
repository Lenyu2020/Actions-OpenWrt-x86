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
echo "src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall.git;main" >> "feeds.conf.default"
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
set -u
set -o pipefail

########################################
# 固定通道（不要改，除非你知道自己在干嘛）
########################################
CHANNEL_PREFIX="23.05-24.10"
PKG_EXT="ipk"

########################################
# 路径与常量
########################################
TEMP_DIR="/tmp/passwall_update"
RULE_DIR="/usr/share/passwall/rules"
RULE_BACKUP="/tmp/passwall_rule_backup"
PSVERSION_FILE="/usr/share/psversion"

RED='\033[0;31m'; BLUE='\033[0;34m'; ORANGE='\033[0;33m'; NC='\033[0m'
echo_red(){ echo -e "${RED}$1${NC}"; }
echo_blue(){ echo -e "${BLUE}$1${NC}"; }
echo_orange(){ echo -e "${ORANGE}$1${NC}"; }

echo_blue "== Passwall 更新脚本（23.05-24.10 锁定版）=="

########################################
# 0. 记录已安装的后端
########################################
echo_blue "检测已安装的后端组件..."
BACKENDS="sing-box xray-core v2ray-plugin haproxy ipt2socks geoview"
SAVED_BACKENDS=""
for p in $BACKENDS; do
  opkg list-installed | awk '{print $1}' | grep -qx "$p" && SAVED_BACKENDS="$SAVED_BACKENDS $p"
done

########################################
# 1. 获取 GitHub 最新 release
########################################
echo_blue "获取 GitHub 最新 release..."

fetch_latest_json() {
  command -v curl >/dev/null 2>&1 && \
    curl -s https://api.github.com/repos/Openwrt-Passwall/openwrt-passwall/releases/latest \
    || wget -qO- https://api.github.com/repos/Openwrt-Passwall/openwrt-passwall/releases/latest
}

latest_release="$(fetch_latest_json)"

########################################
# 2. 严格匹配 23.05-24.10 的 ipk（只取一个）
########################################
match_pkg() {
  echo "$latest_release" | \
    grep -o "\"browser_download_url\": \"[^\"]*${CHANNEL_PREFIX}_luci-${1}_[0-9.]\+\(-r[0-9]\+\)\?_all\.${PKG_EXT}\"" | \
    sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/' | \
    head -n 1
}

luci_app_passwall_url="$(match_pkg "app-passwall")"
luci_i18n_passwall_url="$(match_pkg "i18n-passwall-zh-cn")"

[ -z "$luci_app_passwall_url" ] && {
  echo_red "未找到 ${CHANNEL_PREFIX} 的 luci-app-passwall 包"
  exit 1
}

[ -z "$luci_i18n_passwall_url" ] && {
  echo_red "未找到 ${CHANNEL_PREFIX} 的中文语言包"
  exit 1
}

app_file="$(basename "$luci_app_passwall_url")"
i18n_file="$(basename "$luci_i18n_passwall_url")"

########################################
# 3. 提取技术版本号（忽略 -r）
########################################
version_new="$(echo "$app_file" | sed -E 's/.*_([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
echo_blue "最新技术版本：$version_new"

########################################
# 4. 本地版本检查（忽略 -r）
########################################
installed_version="$(opkg list-installed | grep '^luci-app-passwall ' | awk '{print $3}' | \
  sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
installed_version="${installed_version:-无}"

echo_blue "当前本地版本：$installed_version"

if [ "$installed_version" = "$version_new" ]; then
  echo_blue "技术版本一致，无需更新。"
  exit 0
fi

########################################
# 5. 用户确认
########################################
echo_orange "即将更新到 $version_new，继续？(y/n, 默认 y)"
read -t 10 -r reply || true
reply=${reply:-y}
[ "$reply" = "y" ] || exit 0

########################################
# 6. 下载新版本
########################################
echo_blue "下载 Passwall 包..."
mkdir -p "$TEMP_DIR"

wget -O "$TEMP_DIR/$app_file" "$luci_app_passwall_url" || {
  echo_red "主程序下载失败"
  exit 1
}

wget -O "$TEMP_DIR/$i18n_file" "$luci_i18n_passwall_url" || {
  echo_red "中文包下载失败"
  exit 1
}

########################################
# 7. 备份自定义规则
########################################
echo_blue "备份自定义规则..."
mkdir -p "$RULE_BACKUP"
for f in direct_host direct_ip proxy_host; do
  [ -f "$RULE_DIR/$f" ] && cp "$RULE_DIR/$f" "$RULE_BACKUP/$f"
done

########################################
# 8. 停止 Passwall + 清理 nft
########################################
echo_blue "停止 Passwall..."
/etc/init.d/passwall stop 2>/dev/null || true
sleep 1

echo_blue "清理 nft 规则..."
nft flush ruleset 2>/dev/null || true
for table in passwall passwall_chn passwall_geo passwall1; do
  nft delete table inet "$table" 2>/dev/null || true
done

########################################
# 9. 安装新版本（保留配置）
########################################
echo_blue "安装新版本..."
opkg install "$TEMP_DIR/$app_file" --force-overwrite --force-reinstall 2>&1 | \
  grep -v "Not deleting modified conffile" || true

opkg install "$TEMP_DIR/$i18n_file" --force-overwrite --force-reinstall 2>&1 | \
  grep -v "Not deleting modified conffile" || true

########################################
# 10. 恢复自定义规则
########################################
echo_blue "恢复自定义规则..."
for f in direct_host direct_ip proxy_host; do
  [ -f "$RULE_BACKUP/$f" ] && cp "$RULE_BACKUP/$f" "$RULE_DIR/$f"
done

########################################
# 11. 恢复后端组件
########################################
echo_blue "恢复后端组件..."
for p in $SAVED_BACKENDS; do
  opkg list-installed | awk '{print $1}' | grep -qx "$p" || {
    echo_orange "重新安装后端：$p"
    opkg install "$p" --force-overwrite
  }
done

########################################
# 12. 重启 Passwall
########################################
echo_blue "重启 Passwall..."
/etc/init.d/passwall restart 2>/dev/null || true

echo "$version_new" > "$PSVERSION_FILE"

rm -rf "$TEMP_DIR" "$RULE_BACKUP"

echo_blue "=== Passwall 更新完成（23.05-24.10 最终锁定版,马上重启系统）==="
reboot
exit 0
EOF


