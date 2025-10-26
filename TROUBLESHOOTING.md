# 🔧 故障排除指南

## 快速诊断

```bash
# 1. 运行健康检查脚本
bash check-system.sh

# 2. 查看容器状态
docker compose ps

# 3. 查看实时日志
docker compose logs -f
```

---

## 常见问题及解决方案

### 1. 🔴 Nginx 返回 404 错误

**症状:**
```
nginx    | 2025/10/26 01:28:25 [error] ... "/usr/share/nginx/html/index.html" is not found
```

**原因分析:**
- 前端文件未正确复制
- 使用了旧版本的 index.html
- Docker 卷挂载问题

**解决方案:**

```bash
# 方案 1: 确保使用优化版本
cp frontend/index-optimized.html frontend/index.html
ls -lh frontend/index.html  # 应该显示 100KB+ 的文件

# 方案 2: 重启 Nginx 容器
docker compose restart nginx

# 方案 3: 完全重建
docker compose down
docker compose up -d
```

---

### 2. 🔴 后端容器不断重启

**症状:**
```bash
$ docker ps
CONTAINER ID   STATUS
xxx            Restarting (1) 35 seconds ago
```

**原因分析:**
- Python 依赖安装失败
- 环境变量配置错误
- DashScope SDK 导入问题

**解决方案:**

```bash
# 1. 查看后端错误日志
docker compose logs --tail 50 backend

# 2. 检查环境变量
cat backend/.env

# 3. 重新构建镜像（强制）
docker compose down
docker compose build --no-cache
docker compose up -d

# 4. 进入容器调试
docker compose exec backend bash
python -c "from dashscope import Application; print('OK')"
```

---

### 3. 🔴 API Key 或 App ID 错误

**症状:**
```
status_code=401
message=Invalid API Key
```

**解决方案:**

```bash
# 1. 编辑 .env 文件
nano backend/.env

# 2. 确保正确配置
DASHSCOPE_API_KEY=sk-31d4c4895a6d4a959fa9f4ff029515ac
DASHSCOPE_APP_ID=6596ab6827f445f08abc4194be485bc1

# 3. 重启后端
docker compose restart backend

# 4. 测试 API
docker compose exec backend python -c "
import os
print('API Key:', os.getenv('DASHSCOPE_API_KEY', 'NOT SET'))
print('App ID:', os.getenv('DASHSCOPE_APP_ID', 'NOT SET'))
"
```

---

### 4. 🔴 无法从外部访问网站

**症状:**
- 本地 `curl http://localhost/` 正常
- 外部访问 `http://8.137.51.166` 超时

**原因分析:**
- **阿里云安全组**未开放端口
- 服务器防火墙阻止
- Docker 网络配置问题

**解决方案:**

#### A. 检查阿里云安全组（最常见）

1. 登录阿里云控制台
2. 进入 **ECS 实例** > **安全组**
3. 添加入方向规则:
   - 端口范围: `80/80`
   - 授权对象: `0.0.0.0/0`
   - 协议: `TCP`
   
4. 同样添加 443 端口（HTTPS）

#### B. 检查服务器防火墙

```bash
# 查看防火墙状态
sudo firewall-cmd --list-all

# 开放端口
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload

# 或者临时关闭测试（不推荐生产环境）
sudo systemctl stop firewalld
```

#### C. 验证端口监听

```bash
# 检查端口是否监听
sudo ss -tlnp | grep ':80'

# 测试本地访问
curl -I http://localhost/
curl -I http://127.0.0.1/

# 测试公网 IP（从服务器本机）
curl -I http://8.137.51.166/
```

---

### 5. 🔴 前端无法连接后端 API

**症状:**
- 浏览器控制台显示 `Failed to fetch`
- API 请求返回 502/504

**原因分析:**
- Nginx 代理配置错误
- 后端服务未启动
- 网络隔离问题

**解决方案:**

```bash
# 1. 检查后端是否运行
docker compose ps backend

# 2. 测试 Nginx -> 后端连接
docker exec memory-reconstruction-nginx wget -O- http://backend:8000/
# 应该返回: {"status":"running",...}

# 3. 测试 API 代理
curl http://localhost/api/sessions

# 4. 检查 Nginx 配置
docker exec memory-reconstruction-nginx cat /etc/nginx/conf.d/default.conf

# 5. 查看 Nginx 错误日志
docker compose logs nginx | grep error
```

---

### 6. 🔴 数据库相关错误

**症状:**
```
sqlite3.OperationalError: unable to open database file
```

**解决方案:**

```bash
# 1. 检查数据目录权限
ls -la backend/data/

# 2. 创建并设置权限
mkdir -p backend/data
chmod 755 backend/data

# 3. 重启后端
docker compose restart backend

# 4. 验证数据库
docker compose exec backend python -c "
import sqlite3
conn = sqlite3.connect('./data/sessions.db')
print('Database OK')
"
```

---

### 7. 🔴 Docker Compose 版本问题

**症状:**
```
WARN[0000] /path/docker-compose.yml: `version` is obsolete
```

**说明:** 这是一个警告，不影响运行。Docker Compose v2 不再需要 `version` 字段。

**解决方案（可选）:**

编辑 `docker-compose.yml`，删除第一行的 `version: '3.8'`。

---

### 8. 🟡 页面加载缓慢

**可能原因:**
- CDN 资源加载慢
- API 响应慢
- 网络延迟

**解决方案:**

```bash
# 1. 检查 CDN 可访问性
curl -I https://cdn.jsdelivr.net/npm/vue@3/dist/vue.global.prod.js

# 2. 监控后端响应时间
time curl http://localhost/api/sessions

# 3. 查看后端日志中的处理时间
docker compose logs backend | grep "ms"
```

---

### 9. 🔴 构建镜像失败

**症状:**
```
ERROR: failed to solve: process "/bin/sh -c pip install ..." did not complete successfully
```

**解决方案:**

```bash
# 1. 检查 requirements.txt
cat backend/requirements.txt

# 2. 清理 Docker 缓存
docker builder prune -a

# 3. 重新构建（完全无缓存）
docker compose build --no-cache --pull

# 4. 如果网络问题，使用国内镜像
# 在 Dockerfile 中添加:
# RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

---

### 10. 🔴 容器内存或 CPU 过高

**诊断:**

```bash
# 查看资源使用
docker stats

# 查看容器详细信息
docker inspect memory-reconstruction-backend
docker inspect memory-reconstruction-nginx
```

**解决方案:**

在 `docker-compose.yml` 中添加资源限制:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

---

## 完全重置

如果以上方法都无法解决，执行完全重置：

```bash
# ⚠️ 警告: 这会删除所有数据和容器！

# 1. 停止并删除所有容器
docker compose down -v

# 2. 删除镜像
docker rmi memory-reconstruction-backend:latest

# 3. 清理 Docker 系统
docker system prune -af

# 4. 备份数据（如果需要）
cp -r backend/data backend/data.backup

# 5. 重新部署
bash deploy-production.sh
```

---

## 获取帮助

如果问题仍未解决，请收集以下信息：

```bash
# 生成诊断报告
{
  echo "=== 系统信息 ==="
  uname -a
  docker --version
  docker compose version
  
  echo -e "\n=== 容器状态 ==="
  docker compose ps
  
  echo -e "\n=== 后端日志（最后 50 行）==="
  docker compose logs --tail 50 backend
  
  echo -e "\n=== Nginx 日志（最后 50 行）==="
  docker compose logs --tail 50 nginx
  
  echo -e "\n=== 网络测试 ==="
  curl -v http://localhost/
  curl -v http://localhost/api/sessions
  
} > diagnostic-report.txt

echo "诊断报告已保存到: diagnostic-report.txt"
```

---

## 预防性维护

### 定期备份

```bash
# 备份数据库
cp backend/data/sessions.db backend/data/sessions.db.backup-$(date +%Y%m%d)

# 备份配置
tar -czf config-backup-$(date +%Y%m%d).tar.gz backend/.env docker-compose.yml
```

### 日志清理

```bash
# Docker 日志可能占用大量空间
docker system df

# 清理旧日志
docker system prune -f
```

### 更新检查

```bash
# 更新 Docker 镜像
docker compose pull

# 重新构建并部署
docker compose up -d --build
```

---

## 监控脚本

创建定时检查脚本 `/etc/cron.d/memory-reconstruction`:

```bash
# 每 5 分钟检查一次
*/5 * * * * root cd /var/www/shangyu.icu/yuanshi && bash check-system.sh > /dev/null 2>&1
```

---

**最后更新:** 2025-10-26  
**版本:** 2.0

