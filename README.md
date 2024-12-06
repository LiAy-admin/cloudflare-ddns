# Cloudflare DDNS 更新脚本

将动态IP解析到 Cloudflare 的域名上，这是一个用于自动更新 Cloudflare DNS 记录的 Shell 脚本，支持动态 IP 地址更新。

## 功能特点

- 自动获取公网 IP
- 自动更新 DNS 记录
- 支持定时更新（每5分钟）
- 完整的错误处理和日志记录
- 命令行管理工具
- 中文友好界面

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

## 使用方法

安装完成后，可以使用以下命令：

```bash
# 手动更新 DNS
cloudflare-ddns update

# 启用自动更新
cloudflare-ddns enable

# 禁用自动更新
cloudflare-ddns disable

# 卸载服务
cloudflare-ddns uninstall

# 查看帮助
cloudflare-ddns -h
```

## Cloudflare 配置说明

1. 登录 [Cloudflare](https://dash.cloudflare.com)
2. 获取 Global API Key：
   - 点击右上角的个人资料
   - 选择 "API Tokens"
   - 查看 "Global API Key"
3. 确认域名已添加到 Cloudflare
4. 在 DNS 设置中添加 A 记录（如果还没有）

## 配置文件

- 配置文件位置：`/usr/local/cloudflare-ddns/config`
- 脚本位置：`/usr/local/cloudflare-ddns/cloudflare-ddns.sh`
- 权限设置：600（仅 root 可读写）

## 日志查看

```bash
# 查看实时日志
tail -f /var/log/syslog | grep cloudflare-ddns

# 查看定时任务状态
crontab -l | grep cloudflare-ddns
```

## 常见问题

1. 依赖安装：
```bash
# 安装必要的工具
apt update
apt install curl jq wget -y
```

2. 权限问题：
```bash
# 确保脚本有执行权限
chmod +x cloudflare-ddns.sh
```

3. 定时任务未生效：
```bash
# 重新启用定时更新
cloudflare-ddns enable
```

## 安全建议

1. 定期更新 Cloudflare API Key
2. 确保配置文件权限正确（600）
3. 保护好配置文件中的敏感信息
4. 定期检查运行日志

## 项目地址

- [GitHub 仓库](https://github.com/LiAy-admin/cloudflare-ddns)

## 更新日志

- v1.0.0
  - 初始版本发布
  - 支持自动更新 DNS 记录
  - 添加命令行管理工具
  - 支持定时更新功能

## 许可证

MIT License

## 作者

LiAy-admin

## 贡献

欢迎提交 Issue 和 Pull Request！
