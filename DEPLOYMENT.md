# 🚀 部署指南

本文档详细说明如何在服务器上部署"Memory Reconstruction 测试平台"。

## 服务器信息

- **域名**: shangyu.icu
- **公网IP**: 8.137.51.166
- **内网IP**: 172.19.29.25
- **系统**: Alibaba Cloud Linux 3 (基于 RHEL/CentOS)

## 快速部署

### 方式一：使用自动部署脚本（推荐）

```bash
# 1. 上传项目文件到服务器
scp -r yuanshi root@8.137.51.166:/var/www/shangyu.icu

# 2. SSH连接到服务器
ssh root@8.137.51.166

# 3. 进入项目目录
cd /var/www/shangyu.icu

# 4. 给部署脚本执行权限
chmod +x deploy/deploy.sh

# 5. 运行部署脚本
sudo bash deploy/deploy.sh
```

脚本会自动完成：
- ✅ 安装系统依赖（Python、Nginx等）
- ✅ 安装Python包
- ✅ 配置systemd服务
- ✅ 配置Nginx反向代理
- ✅ （可选）安装SSL证书

### 方式二：手动部署

#### 步骤1: 准备环境

```bash
# 更新系统
sudo yum check-update
sudo yum update -y

# 或使用 dnf（较新版本）
sudo dnf check-update
sudo dnf update -y

# 安装 EPEL 仓库
sudo yum install -y epel-release

# 安装依赖
sudo yum install -y python3 python3-pip python3-devel nginx git curl gcc

# 或使用 dnf
sudo dnf install -y python3 python3-pip python3-devel nginx git curl gcc
```

#### 步骤2: 上传项目文件

```bash
# 方式A: 使用SCP
scp -r yuanshi root@8.137.51.166:/var/www/shangyu.icu

# 方式B: 使用Git
cd /var/www
git clone <your-repository> shangyu.icu
```

#### 步骤3: 安装Python依赖

```bash
cd /var/www/shangyu.icu/backend
pip3 install -r requirements.txt
```

#### 步骤4: 配置环境变量

```bash
# 编辑.env文件
nano .env

# 确保以下配置正确:
# DASHSCOPE_API_KEY=sk-31d4c4895a6d4a959fa9f4ff029515ac
# APP_ID=6596ab6827f445f08abc4194be485bc1
# HOST=0.0.0.0
# PORT=8000
```

#### 步骤5: 配置systemd服务

```bash
# 复制服务文件
sudo cp deploy/systemd.service /etc/systemd/system/data-expert.service

# 重新加载systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl enable data-expert
sudo systemctl start data-expert

# 检查状态
sudo systemctl status data-expert
```

#### 步骤6: 配置Nginx

```bash
# 复制nginx配置
sudo cp deploy/nginx.conf /etc/nginx/sites-available/shangyu.icu

# 启用站点
sudo ln -s /etc/nginx/sites-available/shangyu.icu /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重载nginx
sudo systemctl reload nginx
```

#### 步骤7: 配置防火墙

```bash
# Alibaba Cloud Linux / RHEL / CentOS 使用 firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# 允许HTTP、HTTPS和后端端口
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload

# 查看规则
sudo firewall-cmd --list-all
```

#### 步骤8: 安装SSL证书

```bash
# 安装certbot
sudo yum install -y certbot python3-certbot-nginx
# 或使用 dnf
sudo dnf install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d shangyu.icu -d www.shangyu.icu

# 设置自动续期（添加到 crontab）
echo "0 0,12 * * * root certbot renew --quiet" | sudo tee -a /etc/crontab

# 或查看是否有 timer
sudo systemctl list-timers | grep certbot
```

## 验证部署

### 1. 检查后端服务

```bash
# 查看服务状态
sudo systemctl status data-expert

# 查看日志
sudo journalctl -u data-expert -n 50 -f

# 测试API
curl http://localhost:8000
```

### 2. 检查Nginx

```bash
# 测试nginx配置
sudo nginx -t

# 查看nginx状态
sudo systemctl status nginx

# 查看访问日志
sudo tail -f /var/log/nginx/shangyu_access.log
```

### 3. 测试网站访问

```bash
# 测试HTTP访问
curl -I http://shangyu.icu

# 测试HTTPS访问（如果已配置）
curl -I https://shangyu.icu

# 测试API
curl http://shangyu.icu/api/sessions
```

浏览器访问：
- http://shangyu.icu
- https://shangyu.icu

## 常见问题

### Q1: 服务无法启动

```bash
# 查看详细错误日志
sudo journalctl -u data-expert -xe

# 可能的原因：
# 1. 端口8000被占用
sudo lsof -i :8000
# 或使用 ss
sudo ss -tlnp | grep 8000

# 2. Python依赖未安装
pip3 list | grep dashscope

# 3. 权限问题（Alibaba Cloud Linux 使用 nginx 用户）
sudo chown -R nginx:nginx /var/www/shangyu.icu

# 4. SELinux 问题（RHEL/CentOS 特有）
sudo setenforce 0  # 临时禁用
sudo getenforce    # 查看状态
# 永久禁用（编辑 /etc/selinux/config）
```

### Q2: Nginx 502 Bad Gateway

```bash
# 检查后端服务是否运行
sudo systemctl status data-expert

# 检查端口监听
sudo ss -tlnp | grep 8000
# 或
sudo netstat -tlnp | grep 8000

# 检查SELinux（RHEL/CentOS 特有，重要！）
sudo getenforce  # 查看状态

# 临时禁用 SELinux 测试
sudo setenforce 0

# 如果禁用后正常，需要配置 SELinux 策略
sudo setsebool -P httpd_can_network_connect 1
sudo setenforce 1  # 重新启用

# 或永久禁用 SELinux（不推荐）
# 编辑 /etc/selinux/config，设置 SELINUX=disabled
# 然后重启系统
```

### Q3: 数据库权限错误

```bash
# 创建数据目录
mkdir -p /var/www/shangyu.icu/backend/data

# 设置权限
sudo chown -R www-data:www-data /var/www/shangyu.icu/backend/data
sudo chmod -R 755 /var/www/shangyu.icu/backend/data
```

### Q4: CORS跨域问题

编辑 `backend/server.py`，修改CORS配置：

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://shangyu.icu",
        "https://shangyu.icu",
        "http://www.shangyu.icu",
        "https://www.shangyu.icu"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Q5: SSL证书问题

```bash
# 测试SSL配置
sudo certbot certificates

# 手动续期
sudo certbot renew --dry-run

# 强制续期
sudo certbot renew --force-renewal
```

## 维护操作

### 重启服务

```bash
# 重启后端
sudo systemctl restart data-expert

# 重启Nginx
sudo systemctl restart nginx

# 同时重启
sudo systemctl restart data-expert nginx
```

### 查看日志

```bash
# 后端日志（实时）
sudo journalctl -u data-expert -f

# Nginx访问日志
sudo tail -f /var/log/nginx/shangyu_access.log

# Nginx错误日志
sudo tail -f /var/log/nginx/shangyu_error.log
```

### 更新代码

```bash
# 进入项目目录
cd /var/www/shangyu.icu

# 拉取最新代码（如果使用Git）
git pull

# 或上传新文件
# scp -r yuanshi/* root@8.137.51.166:/var/www/shangyu.icu/

# 重启服务
sudo systemctl restart data-expert
```

### 备份数据

```bash
# 备份数据库
sudo cp /var/www/shangyu.icu/backend/data/history.db \
       /var/www/shangyu.icu/backend/data/history_$(date +%Y%m%d).db

# 自动备份脚本（添加到crontab）
# 每天凌晨2点备份
# 0 2 * * * /usr/bin/cp /var/www/shangyu.icu/backend/data/history.db \
#           /var/www/shangyu.icu/backend/data/history_$(date +\%Y\%m\%d).db
```

### 监控性能

```bash
# CPU和内存使用
htop

# 进程状态
ps aux | grep python

# 磁盘使用
df -h

# 网络连接
sudo netstat -tlnp
```

## 安全建议

1. **防火墙配置**
```bash
# Alibaba Cloud Linux / RHEL / CentOS 使用 firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld

sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

2. **定期更新**
```bash
# 系统更新
sudo yum update -y
# 或
sudo dnf update -y

# Python包更新
pip3 install -U dashscope fastapi uvicorn
```

3. **访问控制**
- 限制SSH访问（使用密钥认证）
- 配置fail2ban防止暴力破解
- 使用强密码

4. **日志监控**
```bash
# 安装日志分析工具
sudo yum install -y logwatch
# 或
sudo dnf install -y logwatch

# 配置邮件告警（可选）
```

5. **数据备份**
- 定期备份数据库
- 备份配置文件
- 使用版本控制

## 性能优化

### 1. Nginx优化

编辑 `/etc/nginx/nginx.conf`:

```nginx
worker_processes auto;
worker_connections 2048;

# 启用gzip压缩
gzip on;
gzip_vary on;
gzip_types text/plain text/css application/json application/javascript;

# 缓存配置
open_file_cache max=1000 inactive=20s;
```

### 2. 后端优化

编辑 `backend/server.py`:

```python
# 使用多进程
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "server:app",
        host="0.0.0.0",
        port=8000,
        workers=4  # 根据CPU核心数调整
    )
```

### 3. 数据库优化

```bash
# 定期清理旧数据（可选）
sqlite3 /var/www/shangyu.icu/backend/data/history.db \
  "DELETE FROM messages WHERE created_at < datetime('now', '-30 days');"

# 优化数据库
sqlite3 /var/www/shangyu.icu/backend/data/history.db "VACUUM;"
```

## 监控告警

### 使用Prometheus + Grafana（可选）

```bash
# 安装监控工具
sudo apt install -y prometheus grafana

# 配置监控端点
# 在server.py中添加metrics端点
```

## 联系支持

如遇到问题，请检查：
1. 服务日志：`journalctl -u data-expert -n 100`
2. Nginx日志：`/var/log/nginx/shangyu_*.log`
3. 系统资源：`htop`, `df -h`

---

**部署完成后，请访问 https://shangyu.icu 测试功能！** 🎉

