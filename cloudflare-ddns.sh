#!/bin/bash

# 定义常量
readonly VERSION="1.0.0"
readonly INSTALL_DIR="/usr/local/cloudflare-ddns"
readonly CONFIG_FILE="$INSTALL_DIR/config"
readonly SCRIPT_PATH="$INSTALL_DIR/cloudflare-ddns.sh"
readonly LOCK_FILE="/tmp/cloudflare-ddns.lock"
readonly CRON_JOB="*/5 * * * * $SCRIPT_PATH update"

# 日志函数
log() {
    echo "$1"
    logger -t $(basename $0) -p user.notice "$1"
}

error() {
    log "错误：$1"
    exit 1
}

# 基础检查函数
check_root() {
    [[ $(id -u) != "0" ]] && error "请使用 root 权限运行此脚本"
}

check_network() {
    ping -c 1 cloudflare.com >/dev/null 2>&1 || error "无法连接到 Cloudflare"
}

check_deps() {
    local deps=(curl jq wget)
    for cmd in "${deps[@]}"; do
        command -v $cmd >/dev/null 2>&1 || {
            log "正在安装 $cmd..."
            apt-get update >/dev/null 2>&1
            apt-get install -y $cmd >/dev/null 2>&1
        }
    done
}

# 配置管理
load_config() {
    [[ -f "$CONFIG_FILE" ]] || error "配置文件不存在，请先运行安装"
    source "$CONFIG_FILE"
}

validate_config() {
    local required=("AUTH_EMAIL" "AUTH_KEY" "ZONE_NAME" "RECORD_NAME")
    for var in "${required[@]}"; do
        [[ -z "${!var}" ]] && error "$var 未配置"
    done
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
AUTH_EMAIL="$1"
AUTH_KEY="$2"
ZONE_NAME="$3"
RECORD_NAME="$4"
EOF
    chmod 600 "$CONFIG_FILE"
}

# 安装函数
do_install() {
    check_root
    check_deps
    
    # 检查是否通过管道运行
    if [ ! -t 0 ]; then
        # 如果是通过管道运行，先保存脚本
        cat > "$SCRIPT_PATH"
        chmod 700 "$SCRIPT_PATH"
        log "脚本已下载到 $SCRIPT_PATH"
        log "请运行以下命令继续安装："
        log "sudo $SCRIPT_PATH install"
        exit 0
    fi
    
    # 正常安装流程...
    mkdir -p "$INSTALL_DIR"
    
    # 获取配置
    log "=== Cloudflare DDNS 配置 ==="
    local email key zone record
    
    while [[ -z "$email" ]]; do
        read -p "请输入 Cloudflare 邮箱: " email
    done
    
    while [[ -z "$key" ]]; do
        read -p "请输入 Global API Key: " key
    done
    
    while [[ -z "$zone" ]]; do
        read -p "请输入域名 (example.com): " zone
    done
    
    while [[ -z "$record" ]]; do
        read -p "请输入子域名 (ddns.example.com): " record
    done
    
    # 验证配置
    log "正在验证配置..."
    local verify_result=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone" \
        -H "X-Auth-Email: $email" \
        -H "X-Auth-Key: $key" \
        -H "Content-Type: application/json")
    
    if ! echo "$verify_result" | jq -e '.success' >/dev/null; then
        error "验证失败: 请检查邮箱和 API Key 是否正确"
        error "API 返回: $(echo "$verify_result" | jq -r '.errors[0].message')"
    fi
    
    log "验证成功！"
    
    # 保存配置
    save_config "$email" "$key" "$zone" "$record"
    
    # 复制脚本
    cp "$0" "$SCRIPT_PATH"
    chmod 700 "$SCRIPT_PATH"
    ln -sf "$SCRIPT_PATH" /usr/local/bin/cloudflare-ddns
    
    log "安装完成！"
    
    # 询问是否用自动更新
    read -p "是否启用自动更新(每5分钟)？[y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && enable_cron
}

# 更新DNS记录
do_update() {
    load_config
    validate_config
    check_network
    
    # 获取IP
    local ip=$(curl -s http://ipv4.icanhazip.com)
    [[ -z "$ip" ]] && error "无法获取公网IP"
    log "当前IP: $ip"
    
    # 获取域名ID
    local zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE_NAME" \
        -H "X-Auth-Email: $AUTH_EMAIL" \
        -H "X-Auth-Key: $AUTH_KEY" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')
    
    [[ -z "$zone_id" || "$zone_id" == "null" ]] && error "无法获取域名ID"
    
    # 获取记录ID
    local record_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$RECORD_NAME" \
        -H "X-Auth-Email: $AUTH_EMAIL" \
        -H "X-Auth-Key: $AUTH_KEY" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')
    
    [[ -z "$record_id" || "$record_id" == "null" ]] && error "无法获取记录ID"
    
    # 更新记录
    local result=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
        -H "X-Auth-Email: $AUTH_EMAIL" \
        -H "X-Auth-Key: $AUTH_KEY" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":false}")
    
    if echo "$result" | jq -e '.success' >/dev/null; then
        log "DNS记录已更新: $RECORD_NAME -> $ip"
    else
        error "更新失败: $(echo "$result" | jq -r '.errors[0].message')"
    fi
}

# 定时任务管理
enable_cron() {
    (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH"; echo "$CRON_JOB") | crontab -
    log "已启用自动更新"
}

disable_cron() {
    crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -
    log "已禁用自动更新"
}

# 卸载函数
do_uninstall() {
    check_root
    read -p "确定要卸载吗？[y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disable_cron
        rm -f "$SCRIPT_PATH" "$CONFIG_FILE"
        rm -f /usr/local/bin/cloudflare-ddns
        rmdir --ignore-fail-on-non-empty "$INSTALL_DIR"
        log "卸载完成"
    fi
}

# 主函数
main() {
    case "$1" in
        install)
            do_install
            ;;
        update)
            do_update
            ;;
        enable)
            enable_cron
            ;;
        disable)
            disable_cron
            ;;
        uninstall)
            do_uninstall
            ;;
        -v|--version)
            echo "cloudflare-ddns v$VERSION"
            ;;
        -h|--help)
            echo "用法: $(basename $0) <命令>"
            echo "命令:"
            echo "  install    安装或重新配置"
            echo "  update     更新DNS记录"
            echo "  enable     启用自动更新"
            echo "  disable    禁用自动更新"
            echo "  uninstall  卸载服务"
            ;;
        *)
            error "未知命令，使用 -h 查看帮助"
            ;;
    esac
}

main "$@" 
