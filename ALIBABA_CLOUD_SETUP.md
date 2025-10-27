# 🚀 Alibaba Cloud Linux 3 快速部署指南

**专为阿里云服务器定制的部署步骤**

## 系统信息

- **操作系统**: Alibaba Cloud Linux 3
- **包管理器**: yum / dnf
- **Web服务器用户**: nginx
- **防火墙**: firewalld
- **SELinux**: 默认启用（重要！）

## 一键部署

```bash
# 1. 连接到服务器
ssh root@8.137.51.166

# 2. 上传项目（在本地执行）
scp -r D:\yuanshi root@8.137.51.166:/var/www/shangyu.icu

# 3. 在服务器上执行部署脚本
cd /var/www/shangyu.icu
chmod +x deploy/deploy.sh
sudo bash deploy/deploy.sh
```

## 详细步骤

### 步骤1: 系统准备

```bash
# 更新系统
sudo yum update -y

# 安装 EPEL 仓库（重要！提供额外软件包）
sudo yum install -y epel-release

# 安装基础工具
sudo yum install -y wget curl vim net-tools
```

### 步骤2: 安装依赖

```bash
# 安装 Python 3
sudo yum install -y python3 python3-pip python3-devel

# 安装编译工具（某些 Python 包需要）
sudo yum install -y gcc gcc-c++ make

# 安装 Nginx
sudo yum install -y nginx

# 安装 Git
sudo yum install -y git
```

### 步骤3: 安装 Python 包

```bash
cd /var/www/shangyu.icu/backend

# 升级 pip
pip3 install --upgrade pip

# 安装项目依赖
pip3 install -r requirements.txt
```

### 步骤4: 配置 SELinux（关键步骤！）

```bash
# 检查 SELinux 状态
sudo getenforce

# 方案A: 配置 SELinux 策略（推荐）
sudo setsebool -P httpd_can_network_connect 1

# 方案B: 临时禁用 SELinux（仅测试用）
sudo setenforce 0

# 方案C: 永久禁用 SELinux（不推荐）
# 编辑 /etc/selinux/config
sudo vi /etc/selinux/config
# 修改: SELINUX=disabled
# 保存后重启: sudo reboot
```

**详细 SELinux 配置请参考**: `deploy/SELINUX_CONFIG.md`

### 步骤5: 配置服务

```bash
# 复制 systemd 服务文件
sudo cp deploy/systemd.service /etc/systemd/system/data-expert.service

# 重新加载 systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start data-expert

# 设置开机自启
sudo systemctl enable data-expert

# 检查状态
sudo systemctl status data-expert
```

### 步骤6: 配置 Nginx

```bash
# 复制 Nginx 配置
sudo cp deploy/nginx.conf /etc/nginx/conf.d/shangyu.icu.conf

# 测试配置
sudo nginx -t

# 启动 Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# 重载配置
sudo systemctl reload nginx
```

### 步骤7: 配置防火墙

```bash
# 启动 firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# 添加规则
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload

# 查看规则
sudo firewall-cmd --list-all
```

### 步骤8: 设置文件权限

```bash
# 修改所有者为 nginx 用户
sudo chown -R nginx:nginx /var/www/shangyu.icu

# 设置目录权限
sudo chmod -R 755 /var/www/shangyu.icu

# 数据目录需要写权限
sudo chmod -R 777 /var/www/shangyu.icu/backend/data
```

### 步骤9: 安装 SSL 证书

```bash
# 安装 certbot
sudo yum install -y certbot python3-certbot-nginx

# 申请证书
sudo certbot --nginx -d shangyu.icu -d www.shangyu.icu

# 设置自动续期
echo "0 0,12 * * * root certbot renew --quiet" | sudo tee -a /etc/crontab
```

## 验证部署

```bash
# 1. 检查后端服务
curl http://localhost:8000

# 2. 检查 Nginx
curl http://localhost

# 3. 查看日志
sudo journalctl -u data-expert -f
sudo tail -f /var/log/nginx/access.log
```

## 常见问题（Alibaba Cloud Linux 特有）

### 问题1: SELinux 阻止连接

**症状**: Nginx 502 Bad Gateway

**解决**:
```bash
# 临时禁用测试
sudo setenforce 0

# 如果正常了，配置策略
sudo setsebool -P httpd_can_network_connect 1
sudo setenforce 1
```

### 问题2: 防火墙阻止访问

**症状**: 外网无法访问

**解决**:
```bash
# 检查防火墙状态
sudo firewall-cmd --state

# 查看规则
sudo firewall-cmd --list-all

# 添加规则
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

### 问题3: Nginx 用户权限问题

**症状**: Permission denied

**解决**:
```bash
# Alibaba Cloud Linux 使用 nginx 用户（不是 www-data）
sudo chown -R nginx:nginx /var/www/shangyu.icu
sudo chmod -R 755 /var/www/shangyu.icu
```

### 问题4: Python 包安装失败

**症状**: gcc not found 或编译错误

**解决**:
```bash
# 安装开发工具
sudo yum groupinstall "Development Tools"
sudo yum install -y python3-devel

# 重新安装
pip3 install -r requirements.txt
```

### 问题5: 阿里云安全组设置

**重要**: 需要在阿里云控制台配置安全组规则！

1. 登录阿里云控制台
2. 进入 ECS 实例
3. 点击"安全组配置"
4. 添加入方向规则：
   - 端口 80 (HTTP)
   - 端口 443 (HTTPS)
   - 端口 8000 (后端服务，可选)
5. 授权对象：0.0.0.0/0

## 有用的命令

```bash
# 查看系统信息
cat /etc/os-release

# 查看端口占用
sudo ss -tlnp | grep 8000

# 查看进程
ps aux | grep python

# 查看日志
sudo journalctl -u data-expert -n 100
sudo tail -f /var/log/nginx/error.log

# 重启服务
sudo systemctl restart data-expert
sudo systemctl restart nginx

# 查看 SELinux 状态
sudo sestatus
sudo getenforce

# 查看防火墙
sudo firewall-cmd --list-all
sudo firewall-cmd --state
```

## 性能优化（可选）

```bash
# 1. Nginx worker 进程数（根据 CPU 核心数）
sudo vi /etc/nginx/nginx.conf
# worker_processes auto;

# 2. 后端多进程（修改 server.py）
# uvicorn.run(..., workers=4)

# 3. 开启 HTTP/2
# 在 nginx.conf 中: listen 443 ssl http2;

# 4. 启用 Nginx 缓存
# proxy_cache_path /var/cache/nginx...
```

## 监控和维护

```bash
# 安装监控工具
sudo yum install -y htop iotop

# 查看系统资源
htop

# 查看磁盘使用
df -h

# 查看内存使用
free -h

# 设置日志轮转
sudo vi /etc/logrotate.d/data-expert
```

## 备份策略

```bash
# 备份数据库
cp /var/www/shangyu.icu/backend/data/history.db \
   /var/www/shangyu.icu/backend/data/history_$(date +%Y%m%d).db

# 备份配置
tar -czf /root/backup_$(date +%Y%m%d).tar.gz \
  /var/www/shangyu.icu/backend/.env \
  /etc/nginx/conf.d/shangyu.icu.conf \
  /etc/systemd/system/data-expert.service

# 定期备份（添加到 crontab）
crontab -e
# 0 2 * * * /path/to/backup_script.sh
```

## 快速命令参考

```bash
# 启动所有服务
sudo systemctl start data-expert nginx firewalld

# 停止所有服务
sudo systemctl stop data-expert nginx

# 查看所有状态
sudo systemctl status data-expert nginx

# 查看所有日志
sudo journalctl -u data-expert -u nginx -f

# 完全重启
sudo systemctl restart data-expert nginx
```

## 获取帮助

- 阿里云文档: https://help.aliyun.com/
- Alibaba Cloud Linux: https://www.alibabacloud.com/help/doc-detail/111881.htm
- SELinux 配置: 查看 `deploy/SELINUX_CONFIG.md`

---

**部署完成后访问**: https://shangyu.icu 🎉

