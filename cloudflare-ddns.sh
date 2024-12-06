#!/bin/bash

# 添加日志功能
exec 1> >(logger -s -t $(basename $0)) 2>&1

SCRIPT_PATH="/usr/local/cloudflare-ddns/cloudflare-ddns.sh"
CRON_JOB="*/5 * * * * $SCRIPT_PATH"

# 显示菜单
show_menu() {
    echo "=== Cloudflare DDNS 管理工具 ==="
    echo "1. 安装 DDNS 服务"
    echo "2. 启用定时更新"
    echo "3. 禁用定时更新"
    echo "4. 立即更新 DNS"
    echo "5. 查看运行状态"
    echo "6. 查看日志"
    echo "7. 卸载 DDNS 服务"
    echo "0. 退出"
    echo "=========================="
}

# 安装服务
install_service() {
    # 安装依赖
    apt update
    apt install -y curl jq

    # 创建目录
    mkdir -p /usr/local/cloudflare-ddns

    # 获取用户配置
    echo "=== Cloudflare 配置设置 ==="
    read -p "请输入 Cloudflare 邮箱: " cf_email
    read -p "请输入 Global API Key: " cf_key
    read -p "请输入域名 (例如: example.com): " cf_zone
    read -p "请输入子域名 (例如: ddns.example.com): " cf_record

    # 创建配置文件
    cat > $SCRIPT_PATH << EOF
#!/bin/bash

# 添加日志功能
exec 1> >(logger -s -t \$(basename \$0)) 2>&1

# Cloudflare 配置
AUTH_EMAIL="$cf_email"
AUTH_KEY="$cf_key"
ZONE_NAME="$cf_zone"
RECORD_NAME="$cf_record"

# 获取当前公网IP
IP=\$(curl -s http://ipv4.icanhazip.com)

# 检查IP是否获取成功
if [ -z "\$IP" ]; then
    echo "错误: 无法获取公网IP地址"
    exit 1
fi

echo "当前公网IP: \$IP"

# 获取域名和记录的ID
ZONE_ID=\$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=\$ZONE_NAME" \\
     -H "X-Auth-Email: \$AUTH_EMAIL" \\
     -H "X-Auth-Key: \$AUTH_KEY" \\
     -H "Content-Type: application/json" | jq -r '.result[0].id')

# 检查域名ID是否获取成功
if [ -z "\$ZONE_ID" ] || [ "\$ZONE_ID" = "null" ]; then
    echo "错误: 无法获取域名ID，请检查域名和API密钥是否正确"
    exit 1
fi

echo "域名ID: \$ZONE_ID"

RECORD_ID=\$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/\$ZONE_ID/dns_records?name=\$RECORD_NAME" \\
     -H "X-Auth-Email: \$AUTH_EMAIL" \\
     -H "X-Auth-Key: \$AUTH_KEY" \\
     -H "Content-Type: application/json" | jq -r '.result[0].id')

# 检查记录ID是否获取成功
if [ -z "\$RECORD_ID" ] || [ "\$RECORD_ID" = "null" ]; then
    echo "错误: 无法获取记录ID，请检查子域名是否正确"
    exit 1
fi

echo "记录ID: \$RECORD_ID"

# 更新DNS记录
UPDATE_RESULT=\$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/\$ZONE_ID/dns_records/\$RECORD_ID" \\
     -H "X-Auth-Email: \$AUTH_EMAIL" \\
     -H "X-Auth-Key: \$AUTH_KEY" \\
     -H "Content-Type: application/json" \\
     --data "{\"type\":\"A\",\"name\":\"\$RECORD_NAME\",\"content\":\"\$IP\",\"ttl\":1,\"proxied\":false}")

# 检查更新是否成功
if echo "\$UPDATE_RESULT" | jq -e '.success' >/dev/null; then
    echo "DNS记录更新成功: \$RECORD_NAME -> \$IP"
else
    echo "错误: DNS记录更新失败"
    echo "错误信息: \$(echo "\$UPDATE_RESULT" | jq -r '.errors[0].message')"
    exit 1
fi
EOF

    # 设置权限
    chmod 700 $SCRIPT_PATH

    echo "DDNS 服务安装完成"
    
    # 询问是否立即启用定时更新
    echo -n "是否立即启用定时更新？(y/n): "
    read enable_auto
    if [ "$enable_auto" = "y" ] || [ "$enable_auto" = "Y" ]; then
        enable_cron
    fi
}

# 卸载服务
uninstall_service() {
    echo -n "确定要卸载 DDNS 服务吗？(y/n): "
    read confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        # 禁用定时任务
        disable_cron
        
        # 删除脚本文件
        rm -f $SCRIPT_PATH
        
        # 删除软链接
        rm -f /usr/local/bin/cloudflare-ddns
        
        # 如果目录为空，删除目录
        rmdir --ignore-fail-on-non-empty /usr/local/cloudflare-ddns
        
        # 清理系统日志中的相关记录
        if [ -f /var/log/syslog ]; then
            sed -i '/cloudflare-ddns/d' /var/log/syslog
        fi
        
        echo "DDNS 服务已卸载"
        echo "如需重新安装，请运行安装脚本"
        exit 0
    else
        echo "取消卸载"
    fi
}

# 启用定时更新
enable_cron() {
    (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH"; echo "$CRON_JOB") | crontab -
    echo "已启用定时更新 (每5分钟)"
}

# 禁用定时更新
disable_cron() {
    crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -
    echo "已禁用定时更新"
}

# 立即更新
update_now() {
    $SCRIPT_PATH
}

# 查看状态
check_status() {
    echo "=== 服务状态 ==="
    if [ -f "$SCRIPT_PATH" ]; then
        echo "脚本位置: $SCRIPT_PATH"
        echo "脚本权限: $(ls -l $SCRIPT_PATH)"
    else
        echo "脚本未安装"
    fi
    
    echo -n "定时任务: "
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        echo "已启用"
    else
        echo "未启用"
    fi
}

# 查看日志
view_logs() {
    tail -f /var/log/syslog | grep cloudflare-ddns
}

# 主循环
while true; do
    show_menu
    read -p "请选择操作 [0-7]: " choice
    case $choice in
        1) install_service ;;
        2) enable_cron ;;
        3) disable_cron ;;
        4) update_now ;;
        5) check_status ;;
        6) view_logs ;;
        7) uninstall_service ;;
        0) exit 0 ;;
        *) echo "无效选项" ;;
    esac
    echo "按回车键继续..."
    read
done 