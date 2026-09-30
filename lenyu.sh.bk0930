#!/bin/bash

# 1. 预先创建依赖目录，防止无写入权限报错
mkdir -p wget files/etc

# 2. 生成版本号 (将不规范的空格统一替换为下划线，保证环境变量安全)
lenyu_version="$(date '+%y%m%d%H%M')_dev_Len_yu" 
echo "$lenyu_version" > wget/DISTRIB_REVISION1 
echo "$lenyu_version" | cut -d '_' -f 1 > files/etc/lenyu_version  

new_DISTRIB_REVISION=$(cat wget/DISTRIB_REVISION1)
TARGET_FILE="package/lean/default-settings/files/zzz-default-settings"

# 容错：确保 zzz-default-settings 文件存在
if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: $TARGET_FILE not found!"
    exit 1
fi

# 3. 动态替换 zzz-default-settings 中的 DISTRIB_REVISION 值
old_DISTRIB_REVISION=$(grep "DISTRIB_REVISION=" "$TARGET_FILE" | cut -d \' -f 2)
if [ -n "$old_DISTRIB_REVISION" ]; then
    sed -i "s/${old_DISTRIB_REVISION}/${new_DISTRIB_REVISION}/" "$TARGET_FILE"
fi

# 4. 注入 Check_Update.sh 别名
if ! grep -q "Check_Update.sh" "$TARGET_FILE"; then
    # 彻底清除文件末尾的 exit 0，防止逻辑中断
    sed -i 's/exit 0//g' "$TARGET_FILE"
    cat >> "$TARGET_FILE" <<-\EOF
	sed -i '$ a alias lenyu="sh /usr/share/Check_Update.sh"' /etc/profile
	chmod 755 /etc/init.d/romupdate
	exit 0
EOF
fi

# 5. 注入 Lenyu-auto.sh 别名
if ! grep -q "Lenyu-auto.sh" "$TARGET_FILE"; then
    sed -i 's/exit 0//g' "$TARGET_FILE"
    cat >> "$TARGET_FILE" <<-\EOF
	sed -i '$ a alias lenyu-auto="sh /usr/share/Lenyu-auto.sh"' /etc/profile
	chmod 755 /etc/init.d/romupdate
	exit 0
EOF
fi

# 6. 注入 Lenyu-pw.sh 别名
if ! grep -q "Lenyu-pw.sh" "$TARGET_FILE"; then
    sed -i 's/exit 0//g' "$TARGET_FILE"
    cat >> "$TARGET_FILE" <<-\EOF
	sed -i '$ a alias lenyu-pw="sh /usr/share/Lenyu-pw.sh"' /etc/profile
	chmod 755 /etc/init.d/romupdate
	exit 0
EOF
fi

# 7. 注入 xray_backup 恢复逻辑 (rc.local)
if ! grep -q "xray_backup" "$TARGET_FILE"; then
    sed -i 's/exit 0//g' "$TARGET_FILE"
    # 这里必须使用 \EOF，确保里层的 $? 等变量原封不动地写入固件，而不是在编译时被提前展开
    cat >> "$TARGET_FILE" <<-\EOF
	cat > /etc/rc.local <<-\EOFF
	# Put your custom commands here that should be executed once
	# the system init finished. By default this file does nothing.
	if [ -f "/etc/xray_backup/xray_backup" ]; then
	    cp -f /etc/xray_backup/xray_backup /usr/bin/xray
	    # Check if the copy operation was successful
	    if [ $? -eq 0 ]; then
	        touch /tmp/xray_succ.log
	    fi
	    rm -rf /etc/xray_backup/xray_backup
	fi
	exit 0
	EOFF
	exit 0
EOF
fi
