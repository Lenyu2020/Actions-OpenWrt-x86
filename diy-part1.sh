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
lenyu_version="`date '+%y%m%d%H%M'`_dev_Len_yu"
echo $lenyu_version >  wget/DISTRIB_REVISION1 
echo $lenyu_version | cut -d _ -f 1 >  files/etc/lenyu_version  
#######
new_DISTRIB_REVISION=`cat  wget/DISTRIB_REVISION1`
grep "DISTRIB_REVISION="  package/lean/default-settings/files/zzz-default-settings | cut -d \' -f 2 >  wget/DISTRIB_REVISION3
old_DISTRIB_REVISION=`cat  wget/DISTRIB_REVISION3`
sed -i "s/${old_DISTRIB_REVISION}/${new_DISTRIB_REVISION}/"   package/lean/default-settings/files/zzz-default-settings
sed -i "s|DISTRIB_REVISION='${new_DISTRIB_REVISION}'|DISTRIB_REVISION=''|" package/lean/default-settings/files/zzz-default-settings
os_release_template="package/base-files/files/usr/lib/os-release"
if [ -f "$os_release_template" ]; then
	sed -i "s|^VERSION=\".*\"|VERSION=\"${new_DISTRIB_REVISION}\"|" "$os_release_template"
	sed -i "s|^BUILD_ID=\".*\"|BUILD_ID=\"\"|" "$os_release_template"
	sed -i "s|^OPENWRT_RELEASE=\".*\"|OPENWRT_RELEASE=\"LEDE ${new_DISTRIB_REVISION}\"|" "$os_release_template"
fi
owrt_release_template="package/base-files/files/etc/openwrt_release"
if [ -f "$owrt_release_template" ]; then
	sed -i "s|^DISTRIB_RELEASE=.*|DISTRIB_RELEASE='${new_DISTRIB_REVISION}'|" "$owrt_release_template"
	sed -i "s|^DISTRIB_REVISION=.*|DISTRIB_REVISION=''|" "$owrt_release_template"
	sed -i "s|^DISTRIB_DESCRIPTION=.*|DISTRIB_DESCRIPTION='LEDE ${new_DISTRIB_REVISION}'|" "$owrt_release_template"
fi
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

cat>files/usr/share/Lenyu-pw.sh<<'EOF_PW'
#!/bin/sh
# 在路由器上直接运行。
# 1. 自动判断发行版、架构、apk 或 opkg
# 2. 写入软件源和公钥，对比已安装版本
# 3. 有更新或未安装时自动安装
#    已装 luci-app-passwall / luci-app-passwall2 就升级已装的那个
#    两个都没装时安装 luci-app-passwall
#    已装的 xray-core、sing-box、chinadns-ng、hysteria、geoview 一并升级
# 4. 再对照 GitHub Releases。luci 包是 all，不看 CPU 架构。
#    25.12 用 25.12+ 的 apk，24.10/23.05 用 23.05-24.10 的 ipk，22.03 用 22.03- 的 ipk。
#    发布页比软件源新时，下载该附件安装。核心组件不在发布页里。
#
# 版本规则：
#   24.10、24.10-SNAPSHOT -> opkg，releases/packages-24.10
#   25.12、25.12-SNAPSHOT -> apk，releases/packages-25.12
#   只有发行版正好是 SNAPSHOT 才用主线快照源
# 下载的索引和公钥暂存在临时目录，退出时删除。软件源配置会留在系统里。
#
#   sh test-passwall-feed.sh
#
# 不在路由器上时，可手动指定（会跳过自动判断）：
#   sh test-passwall-feed.sh --release 24.10 --arch x86_64
#   sh test-passwall-feed.sh --snapshot --arch aarch64_cortex-a53

set -u

BASE="https://master.dl.sourceforge.net/project/openwrt-passwall-build"
FEEDS="passwall_luci passwall_packages passwall2"
RELEASE_FILE="${OPENWRT_RELEASE_FILE:-/etc/openwrt_release}"

REL_ARG=""
ARCH_ARG=""
SNAPSHOT_ARG=0
FORCE=0

usage() {
	echo "用法: sh $0"
	echo "      sh $0 --release 24.10 --arch x86_64"
	echo "      sh $0 --snapshot --arch aarch64_cortex-a53"
	exit 2
}

while [ $# -gt 0 ]; do
	case "$1" in
		--release) REL_ARG="${2:-}"; FORCE=1; shift 2 ;;
		--arch) ARCH_ARG="${2:-}"; FORCE=1; shift 2 ;;
		--snapshot) SNAPSHOT_ARG=1; FORCE=1; shift ;;
		-h|--help) usage ;;
		*) echo "未知参数: $1"; usage ;;
	esac
done

is_num() {
	case "$1" in
		""|*[!0-9]*) return 1 ;;
	esac
	return 0
}

has_cmd() {
	command -v "$1" >/dev/null 2>&1
}

fetch() {
	url="$1"
	dest="$2"
	if has_cmd curl; then
		curl -fsSL --retry 2 --connect-timeout 20 --max-time 120 -o "$dest" "$url"
	elif has_cmd wget; then
		wget -q -O "$dest" "$url"
	else
		echo "需要 curl 或 wget"
		return 1
	fi
}

DISTRIB_ID=""
DISTRIB_RELEASE=""
DISTRIB_ARCH=""
DISTRIB_TARGET=""
SNAPSHOT=0
SERIES=""
PKG_KIND=""
ARCH=""
HAS_APK=0
HAS_OPKG=0

has_cmd apk && HAS_APK=1
has_cmd opkg && HAS_OPKG=1

if [ "$FORCE" -eq 1 ]; then
	ARCH="$ARCH_ARG"
	if [ "$SNAPSHOT_ARG" -eq 1 ]; then
		SNAPSHOT=1
		PKG_KIND="apk"
	else
		SERIES="$REL_ARG"
		case "$SERIES" in
			25.*|26.*|27.*) PKG_KIND="apk" ;;
			*) PKG_KIND="opkg" ;;
		esac
	fi
	if [ -z "$ARCH" ] || { [ "$SNAPSHOT" -eq 0 ] && [ -z "$SERIES" ]; }; then
		usage
	fi
	echo "手动指定，未读 $RELEASE_FILE"
else
	if [ ! -f "$RELEASE_FILE" ]; then
		echo "找不到 $RELEASE_FILE，无法自动判断发行版和架构。"
		echo "请在路由器上执行，或手动加 --release 和 --arch。"
		exit 2
	fi
	# shellcheck disable=SC1090
	. "$RELEASE_FILE"
	ARCH="$DISTRIB_ARCH"
	rel="$DISTRIB_RELEASE"
	echo "ID=$DISTRIB_ID"
	echo "RELEASE=$DISTRIB_RELEASE"
	echo "ARCH=$DISTRIB_ARCH"
	echo "TARGET=$DISTRIB_TARGET"
	echo "本机命令: apk=$([ "$HAS_APK" -eq 1 ] && echo 有 || echo 无) opkg=$([ "$HAS_OPKG" -eq 1 ] && echo 有 || echo 无)"

	if [ -z "$ARCH" ] || [ -z "$rel" ]; then
		echo "发行版文件里没有 DISTRIB_RELEASE 或 DISTRIB_ARCH"
		exit 2
	fi

	# 25.12-SNAPSHOT 仍属于 25.12 分支，不能当成主线 SNAPSHOT。
	case "$rel" in
		SNAPSHOT|snapshot) SNAPSHOT=1 ;;
	esac

	if [ "$SNAPSHOT" -eq 0 ]; then
		major=${rel%%.*}
		rest=${rel#*.}
		minor=${rest%%.*}
		minor=${minor%%-*}
		if ! is_num "$major" || ! is_num "$minor"; then
			echo "无法从 DISTRIB_RELEASE=$rel 解析出版本号"
			exit 2
		fi
		SERIES="${major}.${minor}"
		if [ "$major" -gt 25 ] || { [ "$major" -eq 25 ] && [ "$minor" -ge 12 ]; }; then
			PKG_KIND="apk"
		else
			PKG_KIND="opkg"
		fi
	else
		PKG_KIND="apk"
	fi

	if [ "$PKG_KIND" = "apk" ] && [ "$HAS_APK" -eq 0 ] && [ "$HAS_OPKG" -eq 1 ]; then
		echo "按版本应使用 apk，但这台只有 opkg，改为 opkg。"
		PKG_KIND="opkg"
		if [ "$SNAPSHOT" -eq 1 ]; then
			major=${rel%%.*}
			rest=${rel#*.}
			minor=${rest%%.*}
			minor=${minor%%-*}
			if is_num "$major" && is_num "$minor"; then
				SERIES="${major}.${minor}"
				SNAPSHOT=0
				echo "快照源是 apk 格式，opkg 改用 releases/packages-$SERIES"
			fi
		fi
	fi
	if [ "$PKG_KIND" = "opkg" ] && [ "$HAS_OPKG" -eq 0 ] && [ "$HAS_APK" -eq 1 ]; then
		echo "按版本应使用 opkg，但这台只有 apk，改为 apk。"
		PKG_KIND="apk"
	fi
fi

if [ "$SNAPSHOT" -eq 1 ]; then
	FEED_ROOT="$BASE/snapshots/packages/$ARCH"
	SERIES_LABEL="快照"
else
	FEED_ROOT="$BASE/releases/packages-$SERIES/$ARCH"
	SERIES_LABEL="$SERIES"
fi

echo "判断: 系列=$SERIES_LABEL 架构=$ARCH 包管理器=$PKG_KIND"
echo "软件源根: $FEED_ROOT"
echo

if [ "$PKG_KIND" = "opkg" ] && ! has_cmd gzip; then
	echo "opkg 索引需要 gzip"
	exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/passwall-feed.XXXXXX")"
cleanup() {
	rm -rf "$TMP"
}
trap cleanup EXIT INT TERM

echo "临时目录: $TMP"
echo "== 公钥 =="
if [ "$PKG_KIND" = "opkg" ]; then
	fetch "$BASE/ipk.pub" "$TMP/ipk.pub" || exit 1
	echo "ipk.pub $(wc -c < "$TMP/ipk.pub" | tr -d ' ') bytes"
else
	fetch "$BASE/apk.pub" "$TMP/apk.pub" || exit 1
	echo "apk.pub $(wc -c < "$TMP/apk.pub" | tr -d ' ') bytes"
fi
echo

fail=0
echo "== 索引 =="
for feed in $FEEDS; do
	if [ "$PKG_KIND" = "apk" ]; then
		url="$FEED_ROOT/$feed/packages.adb"
		dest="$TMP/${feed}.adb"
		if fetch "$url" "$dest"; then
			echo "[ok] $feed $(wc -c < "$dest" | tr -d ' ') bytes"
			echo "     $url"
			grep -a -o 'luci-app-passwall[0-9]*' "$dest" 2>/dev/null | sort -u | while read -r name; do
				echo "     $name"
			done
		else
			echo "[失败] $url"
			fail=1
		fi
		continue
	fi

	url="$FEED_ROOT/$feed/Packages.gz"
	dest="$TMP/${feed}.Packages.gz"
	if ! fetch "$url" "$dest"; then
		echo "[失败] $url"
		fail=1
		continue
	fi
	echo "[ok] $feed $(wc -c < "$dest" | tr -d ' ') bytes"
	gzip -dc "$dest" | awk '
		/^Package: / { pkg = $2; ver = "" }
		/^Version: / { ver = $2 }
		/^$/ {
			if (pkg ~ /^(luci-app-passwall2?|xray-core|sing-box|chinadns-ng|hysteria)$/)
				printf "     %s  %s\n", pkg, ver
			pkg = ""
		}
		END {
			if (pkg ~ /^(luci-app-passwall2?|xray-core|sing-box|chinadns-ng|hysteria)$/)
				printf "     %s  %s\n", pkg, ver
		}
	'
done
echo

is_installed() {
	pkg="$1"
	if [ "$PKG_KIND" = "apk" ]; then
		apk info -e "$pkg" >/dev/null 2>&1
	else
		opkg list-installed "$pkg" 2>/dev/null | grep -q .
	fi
}

opkg_ver() {
	pkg="$1"
	mode="$2"
	if [ "$mode" = "installed" ]; then
		opkg list-installed "$pkg" 2>/dev/null | awk -F ' - ' 'NR==1 { print $2 }'
	else
		opkg list "$pkg" 2>/dev/null | awk -F ' - ' 'NR==1 { print $2 }'
	fi
}

apk_vers() {
	pkg="$1"
	apk list "$pkg" 2>/dev/null | while read -r line; do
		case "$line" in
			"$pkg"-*)
				ver=${line#"$pkg-"}
				ver=${ver%% *}
				case "$line" in
					*"[installed]"*) echo "installed $ver" ;;
					*) echo "available $ver" ;;
				esac
				;;
		esac
	done
}

# 26.9.26-r1 高于 26.9.16-r1，也高于 26.9.1-r1。只按数字段比较。
ver_gt() {
	a=$(printf '%s' "$1" | sed 's/[^0-9][^0-9]*/./g; s/^\.//; s/\.$//')
	b=$(printf '%s' "$2" | sed 's/[^0-9][^0-9]*/./g; s/^\.//; s/\.$//')
	while [ -n "$a" ] || [ -n "$b" ]; do
		aa=${a%%.*}
		bb=${b%%.*}
		[ -n "$aa" ] || aa=0
		[ -n "$bb" ] || bb=0
		if [ "$aa" -gt "$bb" ]; then
			return 0
		fi
		if [ "$aa" -lt "$bb" ]; then
			return 1
		fi
		case "$a" in
			*.*) a=${a#*.} ;;
			*) a="" ;;
		esac
		case "$b" in
			*.*) b=${b#*.} ;;
			*) b="" ;;
		esac
	done
	return 1
}

newest_available() {
	best=""
	while read -r kind ver; do
		[ "$kind" = "available" ] || continue
		if [ -z "$best" ] || ver_gt "$ver" "$best"; then
			best=$ver
		fi
	done << EOF
$1
EOF
	printf '%s' "$best"
}

show_log() {
	log="$1"
	grep -v -E 'ERROR: wget: exited with error|WARNING: updating and opening|^ \[' "$log" || true
	n=$(grep -c "unexpected end of file" "$log" 2>/dev/null || true)
	if [ "${n:-0}" -gt 0 ]; then
		echo "已忽略 ${n} 条无关镜像源错误"
	fi
}

echo "== 配置软件源 =="
if [ "$PKG_KIND" = "apk" ] && [ "$HAS_APK" -eq 1 ]; then
	mkdir -p /etc/apk/keys /etc/apk/repositories.d
	cp "$TMP/apk.pub" /etc/apk/keys/openwrt-passwall-build.pem
	echo "公钥: /etc/apk/keys/openwrt-passwall-build.pem"
	list=/etc/apk/repositories.d/customfeeds.list
	touch "$list"
	for feed in $FEEDS; do
		line="$FEED_ROOT/$feed/packages.adb"
		grep -qxF "$line" "$list" 2>/dev/null || echo "$line" >> "$list"
		echo "$line"
	done
	echo "apk update"
	apk update >"$TMP/update.log" 2>&1 || true
	show_log "$TMP/update.log"
	for feed in $FEEDS; do
		url="$FEED_ROOT/$feed/packages.adb"
		if grep -F "WARNING:" "$TMP/update.log" | grep -F "$url" >/dev/null 2>&1; then
			echo "PassWall 软件源更新失败: $url"
			fail=1
		fi
	done
	if [ "$fail" -eq 0 ] && grep -F "WARNING:" "$TMP/update.log" >/dev/null 2>&1; then
		echo "其他软件源的失败已忽略，PassWall 源可用。"
	fi
elif [ "$PKG_KIND" = "opkg" ] && [ "$HAS_OPKG" -eq 1 ]; then
	opkg-key add "$TMP/ipk.pub"
	echo "公钥已加入 opkg"
	conf=/etc/opkg/customfeeds.conf
	touch "$conf"
	for feed in $FEEDS; do
		line="src/gz $feed $FEED_ROOT/$feed"
		grep -qxF "$line" "$conf" 2>/dev/null || echo "$line" >> "$conf"
		echo "$line"
	done
	echo "opkg update"
	opkg update >"$TMP/update.log" 2>&1 || true
	show_log "$TMP/update.log"
	for feed in $FEEDS; do
		if grep -F "$FEED_ROOT/$feed" "$TMP/update.log" | grep -Ei "failed|error|wget" >/dev/null 2>&1; then
			echo "PassWall 软件源更新失败: $FEED_ROOT/$feed"
			fail=1
		fi
	done
	if [ "$fail" -eq 0 ] && grep -Ei "failed|error|wget" "$TMP/update.log" >/dev/null 2>&1; then
		echo "其他软件源的失败已忽略，PassWall 源可用。"
	fi
else
	echo "本机没有 $PKG_KIND，只完成了环境判断，未安装。"
	echo "临时目录将删除。"
	exit "$fail"
fi

if [ "$fail" -ne 0 ]; then
	echo "软件源更新失败，未安装。"
	exit "$fail"
fi
echo

TARGETS=""
if is_installed luci-app-passwall; then
	TARGETS="$TARGETS luci-app-passwall"
fi
if is_installed luci-app-passwall2; then
	TARGETS="$TARGETS luci-app-passwall2"
fi
if [ -z "$TARGETS" ]; then
	TARGETS="luci-app-passwall"
	echo "未安装 PassWall，将安装 luci-app-passwall"
fi
for core in xray-core sing-box chinadns-ng hysteria geoview; do
	if is_installed "$core"; then
		TARGETS="$TARGETS $core"
	fi
done

echo "== 检查并安装 =="
for pkg in $TARGETS; do
	if [ "$PKG_KIND" = "apk" ]; then
		installed_ver=""
		available_ver=""
		vers="$(apk_vers "$pkg")"
		installed_ver=$(printf '%s\n' "$vers" | awk '$1=="installed" { print $2; exit }')
		available_ver=$(newest_available "$vers")
		if [ -z "$installed_ver" ] && ! is_installed "$pkg"; then
			echo "安装 $pkg"
			apk add --no-network "$pkg" >"$TMP/add.log" 2>&1 || fail=1
			show_log "$TMP/add.log"
		elif [ -n "$installed_ver" ] && [ -n "$available_ver" ] && ver_gt "$available_ver" "$installed_ver"; then
			echo "更新 $pkg：$installed_ver -> $available_ver"
			apk add --no-network -u "$pkg" >"$TMP/add.log" 2>&1 || fail=1
			show_log "$TMP/add.log"
		else
			echo "已是软件源最新 $pkg ${installed_ver:-$available_ver}"
		fi
	else
		if ! is_installed "$pkg"; then
			echo "安装 $pkg"
			opkg install "$pkg" || fail=1
			continue
		fi
		inst="$(opkg_ver "$pkg" installed)"
		echo "检查 $pkg 当前 ${inst:-未知}"
		opkg upgrade "$pkg" || fail=1
		now="$(opkg_ver "$pkg" installed)"
		if [ "$now" != "$inst" ]; then
			echo "更新 $pkg：$inst -> $now"
		else
			echo "已是最新 $pkg ${now:-未知}"
		fi
	fi
done
echo

echo "== GitHub 发布包 =="
echo "https://github.com/Openwrt-Passwall/openwrt-passwall/releases"
want_release=0
for pkg in $TARGETS; do
	[ "$pkg" = "luci-app-passwall" ] && want_release=1
done
if [ "$want_release" -eq 0 ]; then
	echo "未选择 luci-app-passwall，跳过发布页。"
else
	api="https://api.github.com/repos/Openwrt-Passwall/openwrt-passwall/releases/latest"
	if has_cmd curl; then
		curl -fsSL -A "passwall-feed" --retry 2 --connect-timeout 20 --max-time 60 -o "$TMP/release.json" "$api"
	elif has_cmd wget; then
		wget -q -O "$TMP/release.json" "$api"
	fi
	tag=$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$TMP/release.json" 2>/dev/null | head -n 1)
	if [ -z "$tag" ]; then
		echo "读发布页失败，软件源结果保持不变。"
	else
		if [ "$PKG_KIND" = "apk" ]; then
			mark="25.12%2B_luci-app-passwall"
			i18nmark="25.12%2B_luci-i18n-passwall"
			ext="apk"
			vers="$(apk_vers luci-app-passwall)"
			inst=$(printf '%s\n' "$vers" | awk '$1=="installed" { print $2; exit }')
		elif [ "$SERIES" = "22.03" ] || [ "$SERIES" = "21.02" ]; then
			mark="22.03-_luci-app-passwall"
			i18nmark="22.03-_luci-i18n-passwall"
			ext="ipk"
			inst="$(opkg_ver luci-app-passwall installed)"
		else
			mark="23.05-24.10_luci-app-passwall"
			i18nmark="23.05-24.10_luci-i18n-passwall"
			ext="ipk"
			inst="$(opkg_ver luci-app-passwall installed)"
		fi
		app_url=$(grep -o 'https://github.com[^" ]*' "$TMP/release.json" | grep '/releases/download/' | grep -F "$mark" | head -n 1)
		i18n_url=$(grep -o 'https://github.com[^" ]*' "$TMP/release.json" | grep '/releases/download/' | grep -F "$i18nmark" | head -n 1)
		echo "发布页 $tag，已安装 ${inst:-无}，附件前缀 $mark"
		if [ -z "$app_url" ]; then
			echo "发布页没有匹配的安装包。"
			fail=1
		elif [ -n "$inst" ] && ! ver_gt "$tag" "$inst"; then
			echo "发布页不高于已安装版本，跳过。"
		else
			echo "下载发布包 $tag"
			if fetch "$app_url" "$TMP/luci-app-passwall.$ext"; then
				if [ "$PKG_KIND" = "apk" ]; then
					apk add --allow-untrusted "$TMP/luci-app-passwall.$ext" >"$TMP/add.log" 2>&1 || fail=1
				else
					opkg install "$TMP/luci-app-passwall.$ext" >"$TMP/add.log" 2>&1 || fail=1
				fi
				show_log "$TMP/add.log"
				if [ -n "$i18n_url" ] && fetch "$i18n_url" "$TMP/luci-i18n-passwall.$ext"; then
					if [ "$PKG_KIND" = "apk" ]; then
						apk add --allow-untrusted "$TMP/luci-i18n-passwall.$ext" >"$TMP/add.log" 2>&1 || true
					else
						opkg install "$TMP/luci-i18n-passwall.$ext" >"$TMP/add.log" 2>&1 || true
					fi
					show_log "$TMP/add.log"
				fi
			else
				echo "下载发布包失败。"
				fail=1
			fi
		fi
	fi
fi
echo
echo "临时目录将删除。"
exit "$fail"
EOF_PW


