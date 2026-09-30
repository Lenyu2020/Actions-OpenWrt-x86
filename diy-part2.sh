#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
sed -i 's/192.168.1.1/10.10.10.1/g' package/base-files/files/bin/config_generate
# 1. 替换 Luci 的默认核心主题依赖
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
# 2. 移除 Lean 源码中硬编码对 Argon 的默认指向
#sed -i 's/luci-theme-argon/luci-theme-design/g' feeds/luci/collections/luci/Makefile
# 3. 强行修改底层默认设置脚本中的初始开机 UI 路径
#sed -i 's/luci-static\/argon/luci-static\/design/g' package/lean/default-settings/files/zzz-default-settings
#sed -i 's/KERNEL_PATCHVER:=5.15/KERNEL_PATCHVER:=6.1/g' target/linux/x86/Makefile
#sed -i "s/.*PKG_VERSION:=.*/PKG_VERSION:=4.3.9_v1.2.14/" package/lean/qBittorrent-static/Makefile
#sed -i "s/.*PKG_VERSION:=.*/PKG_VERSION:=5.0.0-stable/" package/libs/wolfssl/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-light/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-nginx/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-ssl-nginx/Makefile
# 修改升级检测
sed -i 's|/Lenyu2020/Actions-OpenWrt-x86|/mubinsy651/ActionsOpenWrtx86|g' files/usr/share/Check_Update.sh
sed -i 's|/Lenyu2020/Actions-OpenWrt-x86|/mubinsy651/ActionsOpenWrtx86|g' files/usr/share/Lenyu-auto.sh
sed -i 's|/Lenyu2020/Actions-OpenWrt-x86|/mubinsy651/ActionsOpenWrtx86|g' files/usr/share/Lenyu-version.sh
sed -i 's|/Lenyu2020/Actions-OpenWrt-x86|/mubinsy651/ActionsOpenWrtx86|g' files/usr/share/Lenyu-pw.sh



# welcome test
