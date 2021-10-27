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
sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

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
ver414=`grep "LINUX_VERSION-4.14 ="  include/kernel-version.mk | cut -d . -f 3`
ver419=`grep "LINUX_VERSION-4.19 ="  include/kernel-version.mk | cut -d . -f 3`
ver54=`grep "LINUX_VERSION-5.4 ="  include/kernel-version.mk | cut -d . -f 3`
ver510=`grep "LINUX_VERSION-5.10 ="  include/kernel-version.mk | cut -d . -f 3`
if [ "$str1" = "5.4" ];then
   mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver54}_dev_Lenyu.img.gz
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver54}_uefi-gpt_dev_Lenyu.img.gz
  exit 0
elif [ "$str1" = "4.19" ];then
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver419}_dev_Lenyu.img.gz
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver419}_uefi-gpt_dev_Lenyu.img.gz
  exit 0
elif [ "$str1" = "4.14" ];then
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver414}_dev_Lenyu.img.gz
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver414}_uefi-gpt_dev_Lenyu.img.gz
  exit 0
elif [ "$str1" = "5.10" ];then
   mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver510}_dev_Lenyu.img.gz
  mv  bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/openwrt_x86-64-${rename_version}_${str1}.${ver510}_uefi-gpt_dev_Lenyu.img.gz
  exit 0
fi
EOF
