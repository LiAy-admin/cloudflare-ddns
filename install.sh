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
echo "正在安装依赖..."
apt update
apt install -y curl jq wget

# 创建安装目录
mkdir -p /usr/local/cloudflare-ddns

# 下载脚本
echo "正在下载脚本..."
wget -O /usr/local/cloudflare-ddns/cloudflare-ddns.sh https://ghp.ci/https://github.com/LiAy-admin/cloudflare-ddns/releases/download/fc-ddns.sh/cloudflare-ddns.sh

# 设置权限
chmod 700 /usr/local/cloudflare-ddns/cloudflare-ddns.sh

# 创建快捷命令
ln -sf /usr/local/cloudflare-ddns/cloudflare-ddns.sh /usr/local/bin/cloudflare-ddns

echo "安装完成！"
echo "使用方法："
echo "1. 直接运行: cloudflare-ddns"
echo "2. 或者运行: /usr/local/cloudflare-ddns/cloudflare-ddns.sh" 
