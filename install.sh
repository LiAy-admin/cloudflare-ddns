#!/bin/bash

# 一键安装脚本
echo "=== Cloudflare DDNS 一键安装脚本 ==="

# 检查是否为 root
if [ "$(id -u)" != "0" ]; then
    echo "错误：请使用 root 权限运行此脚本"
    echo "使用方法: sudo bash install.sh"
    exit 1
fi

# 安装依赖
echo "正在检查依赖..."
apt-get update >/dev/null 2>&1
apt-get install -y curl jq wget >/dev/null 2>&1

# 创建安装目录
INSTALL_DIR="/usr/local/cloudflare-ddns"
mkdir -p $INSTALL_DIR

# 下载脚本
echo "正在下载脚本..."

# 检查下载结果
download_script() {
    local url=$1
    if wget -q -O $INSTALL_DIR/cloudflare-ddns.sh "$url"; then
        return 0
    fi
    return 1
}

# 尝试从不同源下载
if ! download_script "https://ghp.ci/https://github.com/LiAy-admin/cloudflare-ddns/releases/download/fc-ddns.sh/cloudflare-ddns.sh"; then
    echo "使用备用下载源..."
    if ! download_script "https://github.com/LiAy-admin/cloudflare-ddns/releases/download/fc-ddns.sh/cloudflare-ddns.sh"; then
        echo "错误：脚本下载失败"
        exit 1
    fi
fi

# 设置权限
chmod 700 $INSTALL_DIR/cloudflare-ddns.sh

# 创建快捷命令
ln -sf $INSTALL_DIR/cloudflare-ddns.sh /usr/local/bin/cloudflare-ddns

echo "安装完成！"
echo "使用方法："
echo "1. 直接运行: cloudflare-ddns"
echo "2. 或者运行: $INSTALL_DIR/cloudflare-ddns.sh"
echo ""
echo "提示：首次运行请选择选项 1 进行配置" 
