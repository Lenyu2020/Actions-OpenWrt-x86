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
echo 'src-git passwallluci https://github.com/xiaorouji/openwrt-passwall;luci' >>feeds.conf.default
echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall;packages' >>feeds.conf.default

mkdir -p files/usr/share
mkdir -p files/etc/
touch files/etc/lenyu_version
mkdir wget
touch wget/DISTRIB_REVISION1
touch wget/DISTRIB_REVISION3
touch files/usr/share/Check_Update.sh
touch files/usr/share/Lenyu-auto.sh


cat>rename.sh<<-\EOF
#!/bin/bash
rm -rf  bin/targets/x86/64/config.buildinfo
rm -rf  bin/targets/x86/64/feeds.buildinfo
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-kernel.bin
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.vmdk
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.vmdk
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-rootfs.img.gz
rm -rf  bin/targets/x86/64/openwrt-x86-64-generic.manifest
rm -rf bin/targets/x86/64/sha256sums
rm -rf  bin/targets/x86/64/version.buildinfo
sleep 2
rename_version=`cat files/etc/lenyu_version`
str1=`grep "KERNEL_PATCHVER:="  target/linux/x86/Makefile | cut -d = -f 2` #判断当前默认内核版本号如5.10
ver414=`grep "LINUX_VERSION-4.14 ="  include/kernel-4.14 | cut -d . -f 3`
ver419=`grep "LINUX_VERSION-4.19 ="  include/kernel-4.19 | cut -d . -f 3`
ver54=`grep "LINUX_VERSION-5.4 ="  include/kernel-5.4 | cut -d . -f 3`
ver510=`grep "LINUX_VERSION-5.10 ="  include/kernel-5.10 | cut -d . -f 3`
ver515=`grep "LINUX_VERSION-5.15 ="  include/kernel-5.15 | cut -d . -f 3`
ver60=`grep "LINUX_VERSION-6.0 ="  include/kernel-6.0 | cut -d . -f 3`
if [ "$str1" = "5.4" ];then
   mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver54}_sta_Lenyu.img.gz
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver54}_uefi-gpt_sta_Lenyu.img.gz
elif [ "$str1" = "4.19" ];then
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver419}_sta_Lenyu.img.gz
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver419}_uefi-gpt_sta_Lenyu.img.gz
elif [ "$str1" = "4.14" ];then
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver414}_sta_Lenyu.img.gz
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver414}_uefi-gpt_sta_Lenyu.img.gz
elif [ "$str1" = "5.10" ];then
   mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver510}_sta_Lenyu.img.gz
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver510}_uefi-gpt_sta_Lenyu.img.gz
elif [ "$str1" = "5.15" ];then
   mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver515}_sta_Lenyu.img.gz
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver515}_uefi-gpt_sta_Lenyu.img.gz
elif [ "$str1" = "6.0" ];then
   mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver60}_sta_Lenyu.img.gz
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver60}_uefi-gpt_sta_Lenyu.img.gz
fi
ls bin/targets/x86/64 | grep "_Lenyu.img" | cut -d - -f 3 | cut -d _ -f 1-2 > wget/op_version1
#md5
ls -l  "bin/targets/x86/64" | awk -F " " '{print $9}' > wget/open_sta_md5
sta_version=`grep "_uefi-gpt_sta_Lenyu.img.gz" wget/open_sta_md5 | cut -d - -f 3 | cut -d _ -f 1-2`
openwrt_sta=openwrt_x86-64-${sta_version}_sta_Lenyu.img.gz
openwrt_sta_uefi=openwrt_x86-64-${sta_version}_uefi-gpt_sta_Lenyu.img.gz
cd bin/targets/x86/64
md5sum $openwrt_sta > openwrt_sta.md5
md5sum $openwrt_sta_uefi > openwrt_sta_uefi.md5
exit 0
EOF

cat>lenyu.sh<<-\EOOF
#!/bin/bash
lenyu_version="`date '+%y%m%d%H%M'`_sta_Len yu" 
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
	exit 0
	EOF
fi
grep "Lenyu-auto.sh"  package/lean/default-settings/files/zzz-default-settings
if [ $? != 0 ]; then
	sed -i 's/exit 0/ /'  package/lean/default-settings/files/zzz-default-settings
	cat>> package/lean/default-settings/files/zzz-default-settings<<-EOF
	sed -i '$ a alias lenyu-auto="sh /usr/share/Lenyu-auto.sh"' /etc/profile
	exit 0
	EOF
fi
EOOF

cat>files/usr/share/Check_Update.sh<<-\EOF
#!/bin/bash
# https://github.com/Blueplanet20120/Actions-OpenWrt-x86
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
wget -qO- -t1 -T2 "https://api.github.com/repos/Blueplanet20120/Actions-OpenWrt-x86/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g'  > /tmp/cloud_ts_version
if [ -s  "/tmp/cloud_ts_version" ]; then
	cloud_version=`cat /tmp/cloud_ts_version | cut -d _ -f 1`
	cloud_kernel=`cat /tmp/cloud_ts_version | cut -d _ -f 2`
	#固件下载地址
	new_version=`cat /tmp/cloud_ts_version`
	DEV_URL=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_sta_Lenyu.img.gz
	DEV_UEFI_URL=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
	openwrt_sta=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_sta.md5
	openwrt_sta_uefi=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_sta_uefi.md5
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
		wget -P /tmp "$DEV_URL" -O /tmp/openwrt_x86-64-${new_version}_sta_Lenyu.img.gz
		wget -P /tmp "$openwrt_sta" -O /tmp/openwrt_sta.md5
		cd /tmp && md5sum -c openwrt_sta.md5
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
		wget -P /tmp "$DEV_UEFI_URL" -O /tmp/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
		wget -P /tmp "$openwrt_sta_uefi" -O /tmp/openwrt_sta_uefi.md5
		cd /tmp && md5sum -c openwrt_sta_uefi.md5
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
		gzip -d openwrt_x86-64-${new_version}_sta_Lenyu.img.gz
		sysupgrade /tmp/openwrt_x86-64-${new_version}_sta_Lenyu.img
	else
		gzip -d openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
		sysupgrade /tmp/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img
	fi
    ;;
    n|N)
    echo
    echo -e "\033[32m >>>正在准备不保留配置升级，请稍后，等待系统重启…-> \033[0m"
    echo
    sleep 3
	if [ ! -d /sys/firmware/efi ];then
		gzip -d openwrt_x86-64-${new_version}_sta_Lenyu.img.gz
		sysupgrade -n  /tmp/openwrt_x86-64-${new_version}_sta_Lenyu.img
	else
		gzip -d openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
		sysupgrade -n  /tmp/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img
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
# https://github.com/Blueplanet20120/Actions-OpenWrt-x86
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
wget -qO- -t1 -T2 "https://api.github.com/repos/Blueplanet20120/Actions-OpenWrt-x86/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g'  > /tmp/cloud_ts_version
if [ -s  "/tmp/cloud_ts_version" ]; then
	cloud_version=`cat /tmp/cloud_ts_version | cut -d _ -f 1`
	cloud_kernel=`cat /tmp/cloud_ts_version | cut -d _ -f 2`
	#固件下载地址
	new_version=`cat /tmp/cloud_ts_version`
	DEV_URL=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_sta_Lenyu.img.gz
	DEV_UEFI_URL=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
	openwrt_sta=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_sta.md5
	openwrt_sta_uefi=https://github.com/Blueplanet20120/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_sta_uefi.md5
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
		wget -P /tmp "$DEV_URL" -O /tmp/openwrt_x86-64-${new_version}_sta_Lenyu.img.gz
		wget -P /tmp "$openwrt_sta" -O /tmp/openwrt_sta.md5
		cd /tmp && md5sum -c openwrt_sta.md5
		if [ $? != 0 ]; then
		  echo "您下载文件失败，请检查网络重试…"
		  sleep 4
		  exit
		fi
		gzip -d /tmp/openwrt_x86-64-${new_version}_sta_Lenyu.img.gz
		sysupgrade /tmp/openwrt_x86-64-${new_version}_sta_Lenyu.img
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
else
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_UEFI_URL" -O /tmp/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
		wget -P /tmp "$openwrt_sta_uefi" -O /tmp/openwrt_sta_uefi.md5
		cd /tmp && md5sum -c openwrt_sta_uefi.md5
		if [ $? != 0 ]; then
			echo "您下载文件失败，请检查网络重试…"
			sleep 1
			exit
		fi
		gzip -d /tmp/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
		sysupgrade /tmp/openwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
fi

exit 0
EOF


