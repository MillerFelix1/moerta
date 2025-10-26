# 🐳 Docker 部署指南

**推荐的现代化部署方式 - 一次构建，到处运行**

## 🎯 优势

- ✅ **环境一致性** - 无需关心服务器系统差异
- ✅ **快速部署** - 5分钟内完成部署
- ✅ **易于维护** - 一键启动、停止、重启
- ✅ **版本控制** - 可以轻松回滚
- ✅ **资源隔离** - 不影响系统环境
- ✅ **易于扩展** - 需要时可以横向扩展

## 📋 前提条件

### 在服务器上安装 Docker

```bash
# 连接到服务器
ssh root@8.137.51.166

# 安装 Docker（阿里云 Linux 3）
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# 或使用官方安装脚本
curl -fsSL https://get.docker.com | bash

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
docker --version
docker-compose --version
```

### 安装 Docker Compose

```bash
# 方式1：使用包管理器（推荐）
sudo dnf install -y docker-compose-plugin

# 方式2：手动安装
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证
docker compose version
```

## 🚀 快速部署

### 方式1：直接在服务器上构建（推荐）

```bash
# 1. 上传项目到服务器
scp -r D:\yuanshi root@8.137.51.166:/var/www/shangyu.icu/

# 2. SSH 连接到服务器
ssh root@8.137.51.166

# 3. 进入项目目录
cd /var/www/shangyu.icu/yuanshi

# 4. 确保 .env 文件存在
ls backend/.env

# 5. 构建并启动服务
docker compose up -d --build

# 6. 查看日志
docker compose logs -f
```

### 方式2：本地构建镜像，推送到服务器

```bash
# 在本地构建
cd D:\yuanshi
docker build -t memory-reconstruction:latest .

# 保存镜像
docker save memory-reconstruction:latest | gzip > memory-reconstruction.tar.gz

# 上传到服务器
scp memory-reconstruction.tar.gz root@8.137.51.166:/tmp/

# 在服务器上加载
ssh root@8.137.51.166
docker load < /tmp/memory-reconstruction.tar.gz

# 使用现有镜像启动
cd /var/www/shangyu.icu/yuanshi
docker compose up -d
```

### 方式3：使用镜像仓库（推荐生产环境）

```bash
# 在本地构建并推送到阿里云容器镜像服务
docker build -t registry.cn-hangzhou.aliyuncs.com/yourname/memory-reconstruction:latest .
docker push registry.cn-hangzhou.aliyuncs.com/yourname/memory-reconstruction:latest

# 在服务器上拉取并运行
docker pull registry.cn-hangzhou.aliyuncs.com/yourname/memory-reconstruction:latest
docker compose up -d
```

## 📝 常用命令

### 启动服务

```bash
# 启动所有服务
docker compose up -d

# 仅启动后端
docker compose up -d backend

# 查看状态
docker compose ps
```

### 查看日志

```bash
# 查看所有日志
docker compose logs

# 实时查看日志
docker compose logs -f

# 仅查看后端日志
docker compose logs -f backend

# 查看最近100行
docker compose logs --tail=100
```

### 重启服务

```bash
# 重启所有服务
docker compose restart

# 仅重启后端
docker compose restart backend

# 重新构建并重启
docker compose up -d --build
```

### 停止服务

```bash
# 停止所有服务
docker compose stop

# 停止并删除容器
docker compose down

# 停止并删除容器、网络、镜像
docker compose down --rmi all
```

### 进入容器

```bash
# 进入后端容器
docker compose exec backend bash

# 或使用 sh（Alpine 镜像）
docker compose exec backend sh

# 查看 Python 版本
docker compose exec backend python --version
```

### 更新代码

```bash
# 1. 上传新代码
scp -r backend/* root@8.137.51.166:/var/www/shangyu.icu/yuanshi/backend/

# 2. 重新构建
docker compose up -d --build

# 或不重新构建（如果只改了 Python 代码）
docker compose restart backend
```

## 🔧 配置说明

### 环境变量（backend/.env）

```env
DASHSCOPE_API_KEY=sk-31d4c4895a6d4a959fa9f4ff029515ac
APP_ID=6596ab6827f445f08abc4194be485bc1
HOST=0.0.0.0
PORT=8000
DATABASE_PATH=./data/history.db
```

### 端口映射

- **80** → Nginx (HTTP)
- **443** → Nginx (HTTPS，需要配置 SSL）
- **8000** → 后端 API（可选直接暴露）

### 数据持久化

数据保存在 `./backend/data/` 目录，通过 Docker volume 挂载，不会因为容器重启而丢失。

## 🔒 配置 SSL（HTTPS）

### 使用 Let's Encrypt

```bash
# 1. 安装 certbot
sudo dnf install -y certbot

# 2. 获取证书（确保80端口开放）
sudo certbot certonly --standalone -d shangyu.icu -d www.shangyu.icu

# 3. 证书会保存在
/etc/letsencrypt/live/shangyu.icu/

# 4. 复制到项目目录
sudo mkdir -p /var/www/shangyu.icu/yuanshi/ssl
sudo cp /etc/letsencrypt/live/shangyu.icu/fullchain.pem /var/www/shangyu.icu/yuanshi/ssl/
sudo cp /etc/letsencrypt/live/shangyu.icu/privkey.pem /var/www/shangyu.icu/yuanshi/ssl/

# 5. 修改 nginx-docker.conf，取消 HTTPS 部分的注释

# 6. 重启服务
docker compose restart nginx

# 7. 设置自动续期
echo "0 0 * * * certbot renew --quiet && docker compose -f /var/www/shangyu.icu/yuanshi/docker-compose.yml restart nginx" | sudo tee -a /etc/crontab
```

## 🛡️ 安全建议

### 1. 配置防火墙

```bash
# 开放必要端口
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 2. 限制容器资源

修改 `docker-compose.yml`：

```yaml
services:
  backend:
    # ... 其他配置
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

### 3. 使用非 root 用户运行容器

在 Dockerfile 中添加：

```dockerfile
RUN adduser --disabled-password --gecos '' appuser
USER appuser
```

## 📊 监控和日志

### 查看资源使用

```bash
# 查看容器资源使用
docker stats

# 查看磁盘使用
docker system df

# 清理未使用的资源
docker system prune -a
```

### 日志管理

```bash
# 限制日志大小（修改 docker-compose.yml）
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 🔄 备份和恢复

### 备份数据

```bash
# 备份数据库
docker compose exec backend cp /app/data/history.db /app/data/history_$(date +%Y%m%d).db

# 或直接复制
cp backend/data/history.db backend/data/history_backup.db

# 打包备份
tar -czf backup_$(date +%Y%m%d).tar.gz backend/data/
```

### 恢复数据

```bash
# 停止服务
docker compose stop backend

# 恢复数据
cp backend/data/history_backup.db backend/data/history.db

# 启动服务
docker compose start backend
```

## 🐛 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker compose logs backend

# 查看容器状态
docker compose ps

# 检查配置
docker compose config
```

### 端口冲突

```bash
# 查看端口占用
sudo ss -tlnp | grep 80

# 修改 docker-compose.yml 中的端口映射
ports:
  - "8080:80"  # 改为 8080
```

### 数据库权限问题

```bash
# 设置正确的权限
chmod 777 backend/data/
```

## 📈 性能优化

### 1. 使用多阶段构建

Dockerfile 已经优化过，使用 slim 镜像减小体积。

### 2. 启用 Nginx 缓存

已在 nginx-docker.conf 中配置静态资源缓存。

### 3. 横向扩展

```yaml
services:
  backend:
    deploy:
      replicas: 3  # 运行3个后端实例
```

## 🎉 完成！

部署完成后访问：
- HTTP: http://shangyu.icu
- HTTPS: https://shangyu.icu

查看服务状态：
```bash
docker compose ps
curl http://localhost
```

---

**Docker 部署完美解决了环境依赖问题！** 🐳✨

## 对比：传统部署 vs Docker 部署

| 特性 | 传统部署 | Docker 部署 |
|------|---------|------------|
| 环境配置 | 需要逐个安装依赖 | 一次构建到处运行 |
| 部署时间 | 30+ 分钟 | 5 分钟 |
| 系统兼容性 | 需要适配不同系统 | 完全一致 |
| 版本冲突 | 可能影响系统环境 | 完全隔离 |
| 回滚 | 困难 | 秒级回滚 |
| 扩展 | 复杂 | 简单 |

**推荐使用 Docker 部署！** 🚀

