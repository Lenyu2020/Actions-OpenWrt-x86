#!/bin/bash

TARGET_DIR="bin/targets/x86/64"

# 1. 兜底检查，确保脚本在 openwrt 根目录下执行
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: 找不到 $TARGET_DIR，请确认当前路径。"
    exit 1
fi

# 确保存放 version 记录的目录存在
mkdir -p wget

# 2. 批量清理冗余文件（使用通配符替代硬编码，提升容错且更简洁）
rm -f ${TARGET_DIR}/*.buildinfo
rm -f ${TARGET_DIR}/*.manifest
rm -f ${TARGET_DIR}/sha256sums
rm -f ${TARGET_DIR}/profiles.json
rm -f ${TARGET_DIR}/*-kernel.bin
rm -f ${TARGET_DIR}/*-rootfs.*
rm -f ${TARGET_DIR}/*.vmdk

# 3. 读取前面 lenyu.sh 注入的自定义版本号
if [ -f "files/etc/lenyu_version" ]; then
    rename_version=$(cat files/etc/lenyu_version)
else
    rename_version="unknown"
    echo "Warning: files/etc/lenyu_version 未找到，使用 fallback 版本号。"
fi

# 4. 动态解析内核大版本与补丁号 (增强正则匹配与去空格处理)
kernel_patchver=$(grep "KERNEL_PATCHVER:=" target/linux/x86/Makefile | cut -d '=' -f2 | tr -d ' ')
kernel_include_file="include/kernel-${kernel_patchver}"

if [ -f "$kernel_include_file" ]; then
    # 提取类似 LINUX_VERSION-6.6 = .32 中的 32
    kernel_subver=$(grep "^LINUX_VERSION-${kernel_patchver}" "$kernel_include_file" | awk -F'.' '{print $NF}' | tr -d ' ')
    [ -n "$kernel_subver" ] && ver=".${kernel_subver}" || ver=""
else
    ver=""
fi

# 5. 组合【纯净版号】与【文件名 Base】
# 纯净版号形如：2603081935_6.12.74 (专供前端插件和 GitHub 标题/Tag 使用)
pure_version="${rename_version}_${kernel_patchver}${ver}"
base_name="openwrt_x86-64-${pure_version}"

dest_img_name="${base_name}_dev_Lenyu.img.gz"
dest_efi_name="${base_name}_uefi-gpt_dev_Lenyu.img.gz"

# 6. 切换到目标目录执行重命名与 MD5 生成
cd "$TARGET_DIR" || exit 1

# 处理 Legacy BIOS 传统固件
if [ -f "openwrt-x86-64-generic-squashfs-combined.img.gz" ]; then
    mv "openwrt-x86-64-generic-squashfs-combined.img.gz" "$dest_img_name"
    md5sum "$dest_img_name" > openwrt_dev.md5
else
    echo "Warning: 传统启动镜像文件不存在，已跳过。"
fi

# 处理 UEFI 固件
if [ -f "openwrt-x86-64-generic-squashfs-combined-efi.img.gz" ]; then
    mv "openwrt-x86-64-generic-squashfs-combined-efi.img.gz" "$dest_efi_name"
    md5sum "$dest_efi_name" > openwrt_dev_uefi.md5
else
    echo "Warning: UEFI 镜像文件不存在，已跳过。"
fi

# 7. 回到根目录，生成供 GitHub Actions Release 提取的标签与文件清单
cd - >/dev/null

# 【核心修改点】：这里只输出纯净的版本号给 GitHub，剥离多余的前后缀
echo "$pure_version" > wget/op_version1

ls -1 ${TARGET_DIR} > wget/open_dev_md5

exit 0
