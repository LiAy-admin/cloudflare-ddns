# Cloudflare DDNS 更新脚本

将动态IP解析到 Cloudflare 的域名上，这是一个用于自动更新 Cloudflare DNS 记录的 Shell 脚本，支持动态 IP 地址更新。

## 安装方法

1. 下载脚本：
```bash
wget https://ghp.ci/https://github.com/LiAy-admin/cloudflare-ddns/releases/download/fc-ddns.sh/cloudflare-ddns.sh
```

2. 安装：
```bash
chmod +x cloudflare-ddns.sh
sudo ./cloudflare-ddns.sh install
```

## Cloudflare 配置获取

1. 登录 [Cloudflare](https://dash.cloudflare.com)
2. 获取 Global API Key：
   - 点击右上角的个人资料
   - 选择 "API Tokens"
   - 查看 "Global API Key"
3. 确认域名已添加到 Cloudflare
4. 在 DNS 设置中添加 A 记录（如果还没有）

## 功能说明

脚本提供以下功能：
- 选项 1：安装/重新配置 DDNS 服务
- 选项 2：启用定时更新（每5分钟）
- 选项 3：禁用定时更新
- 选项 4：立即更新 DNS
- 选项 5：查看运行状态
- 选项 6：查看运行日志
- 选项 7：卸载服务
- 选项 0：退出工具

## 常见问题

1. 依赖安装
```bash
# 安装必要的工具
apt update
apt install curl jq -y
```

2. 日志查看：
```bash
# 查看实时日志
tail -f /var/log/syslog | grep cloudflare-ddns
```

## 项目地址

- [GitHub 仓库](https://github.com/LiAy-admin/cloudflare-ddns)

## 安全建议

1. 定期更新 Cloudflare API Key
2. 确保脚本权限正确（700）
3. 保护好配置文件中的敏感信息

## 许可证

MIT License

## 作者

wanqiu9527
