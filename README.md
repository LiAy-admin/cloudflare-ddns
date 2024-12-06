

# Cloudflare DDNS 更新脚本
将动态IP解析到 cloudflare 的域名上
这是一个用于自动更新 Cloudflare DNS 记录的 Shell 脚本，支持动态 IP 地址更新。

## 一键安装

```bash
wget -O- https://gitcode.com/wanqiu9527/cloudflare_DDNS/raw/main/install.sh | sudo bash
```

安装完成后，直接运行：
```bash
cloudflare-ddns
```

## 快速开始

1. 下载脚本：
```bash
wget https://gitcode.com/wanqiu9527/cloudflare_DDNS/raw/main/cloudflare-ddns.sh
```

2. 添加执行权限：
```bash
chmod +x cloudflare-ddns.sh
```

3. 运行脚本：
```bash
./cloudflare-ddns.sh
```

## 首次安装配置

1. 在管理工具中选择 "1" 进行安装
2. 按提示依次输入以下信息：
   - Cloudflare 邮箱
   - Global API Key
   - 域名（例如：example.com）
   - 子域名（例如：ddns.example.com）
3. 选择是否立即启用定时更新

## Cloudflare 配置获取

1. 登录 [Cloudflare](https://dash.cloudflare.com)
2. 获取 Global API Key：
   - 点击右上角的个人资料
   - 选择 "API Tokens"
   - 查看 "Global API Key"
3. 确认域名已添加到 Cloudflare
4. 在 DNS 设置中添加 A 记录（如果还没有）

## 管理工具使用

脚本提供以下功能：
- 选项 1：安装 DDNS 服务
- 选项 2：启用定时更新（每5分钟）
- 选项 3：禁用定时更新
- 选项 4：立即更新 DNS
- 选项 5：查看运行状态
- 选项 6：查看运行日志
- 选项 7：卸载服务
- 选项 0：退出工具

## 常见问题

1. 权限问题：
```bash
# 确保脚本有执行权限
chmod +x cloudflare-ddns.sh
```

2. 依赖安装：
```bash
# 安装必要的工具
apt update
apt install curl jq -y
```

3. 日志查看：
```bash
# 查看实时日志
tail -f /var/log/syslog | grep cloudflare-ddns
```

## 项目地址

- [GitCode 仓库](https://gitcode.com/wanqiu9527/cloudflare_DDNS/blob/main/cloudflare-ddns.sh)

## 安全建议

1. 定期更新 Cloudflare API Key
2. 确保脚本权限正确（700）
3. 保护好配置文件中的敏感信息

## 许可证

MIT License

## 作者

wanqiu9527
