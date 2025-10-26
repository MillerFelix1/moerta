# ⚡ 快速部署指南

## 🎯 适用场景

你已经上传了最新代码到服务器，现在需要快速部署或更新。

---

## 🚀 三步部署（推荐）

### 步骤 1: 进入项目目录

```bash
cd /var/www/shangyu.icu/yuanshi
```

### 步骤 2: 赋予脚本执行权限

```bash
chmod +x deploy-production.sh check-system.sh
```

### 步骤 3: 运行部署脚本

```bash
bash deploy-production.sh
```

✅ 完成！等待 3-5 分钟，访问 https://shangyu.icu

---

## 📋 分步部署（手动控制）

如果你想了解每一步在做什么：

```bash
# 1️⃣ 进入目录
cd /var/www/shangyu.icu/yuanshi

# 2️⃣ 准备前端文件（使用优化版本）
cp frontend/index-optimized.html frontend/index.html
cp PWA-manifest.json frontend/manifest.json

# 3️⃣ 配置环境变量
cat > backend/.env << 'EOF'
DASHSCOPE_API_KEY=sk-31d4c4895a6d4a959fa9f4ff029515ac
DASHSCOPE_APP_ID=6596ab6827f445f08abc4194be485bc1
HOST=0.0.0.0
PORT=8000
DATABASE_PATH=./data/sessions.db
EOF

# 4️⃣ 创建数据目录
mkdir -p backend/data ssl

# 5️⃣ 清理旧容器
docker compose down -v

# 6️⃣ 构建镜像
docker compose build --no-cache

# 7️⃣ 启动服务
docker compose up -d

# 8️⃣ 查看状态
docker compose ps

# 9️⃣ 查看日志
docker compose logs -f
```

---

## 🔄 更新已运行的服务

如果服务已在运行，只需更新代码：

```bash
# 快速更新（不重建镜像）
cd /var/www/shangyu.icu/yuanshi
cp frontend/index-optimized.html frontend/index.html
docker compose restart nginx

# 完整更新（重建镜像）
cd /var/www/shangyu.icu/yuanshi
cp frontend/index-optimized.html frontend/index.html
docker compose down
docker compose build --no-cache
docker compose up -d
```

---

## 🧪 验证部署

### 自动检查

```bash
bash check-system.sh
```

### 手动检查

```bash
# 1. 检查容器状态
docker compose ps
# 期望: 所有服务状态为 "Up"

# 2. 测试后端
curl http://localhost:8000/
# 期望: {"status":"running","service":"数据解构专家测试平台"}

# 3. 测试前端
curl -I http://localhost/
# 期望: HTTP/1.1 200 OK

# 4. 测试 API 代理
curl http://localhost/api/sessions
# 期望: []

# 5. 测试外网访问（替换为你的IP）
curl -I http://8.137.51.166/
# 期望: HTTP/1.1 200 OK
```

---

## 🆘 遇到问题？

### 问题 1: 权限被拒绝

```bash
# 解决方案
sudo chmod +x deploy-production.sh check-system.sh
sudo chown -R $USER:$USER .
```

### 问题 2: Docker 命令未找到

```bash
# 检查 Docker 是否安装
docker --version

# 如果未安装，参考 DOCKER_DEPLOY.md
```

### 问题 3: 端口已被占用

```bash
# 查看占用端口 80 的进程
sudo ss -tlnp | grep ':80'

# 停止冲突的服务
sudo systemctl stop nginx  # 如果系统安装了 Nginx
```

### 问题 4: 外网无法访问

```bash
# 检查阿里云安全组
# 1. 登录阿里云控制台
# 2. ECS -> 安全组
# 3. 添加入站规则: 80/tcp, 0.0.0.0/0

# 检查防火墙
sudo firewall-cmd --list-ports
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --reload
```

### 更多问题

查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 获取详细故障排除指南。

---

## 📚 常用命令速查

```bash
# ===== 服务管理 =====
docker compose up -d              # 启动
docker compose down               # 停止
docker compose restart            # 重启
docker compose ps                 # 状态

# ===== 日志查看 =====
docker compose logs -f            # 所有日志
docker compose logs -f backend    # 后端日志
docker compose logs -f nginx      # Nginx日志
docker compose logs --tail 50     # 最后50行

# ===== 容器操作 =====
docker exec -it memory-reconstruction-backend bash   # 进入后端
docker exec -it memory-reconstruction-nginx sh       # 进入Nginx

# ===== 清理 =====
docker compose down -v            # 停止并删除卷
docker system prune -f            # 清理未使用资源
docker builder prune -a           # 清理构建缓存

# ===== 备份 =====
cp -r backend/data backend/data.backup-$(date +%Y%m%d)

# ===== 健康检查 =====
bash check-system.sh              # 运行检查脚本
curl http://localhost/            # 测试前端
curl http://localhost:8000/       # 测试后端
```

---

## 🎯 一键命令（复制粘贴执行）

### 全新部署

```bash
cd /var/www/shangyu.icu/yuanshi && chmod +x *.sh && bash deploy-production.sh
```

### 快速更新

```bash
cd /var/www/shangyu.icu/yuanshi && cp frontend/index-optimized.html frontend/index.html && docker compose restart nginx
```

### 完整重建

```bash
cd /var/www/shangyu.icu/yuanshi && cp frontend/index-optimized.html frontend/index.html && docker compose down && docker compose build --no-cache && docker compose up -d
```

### 健康检查

```bash
cd /var/www/shangyu.icu/yuanshi && bash check-system.sh
```

### 查看日志

```bash
cd /var/www/shangyu.icu/yuanshi && docker compose logs -f
```

---

## 📊 部署时间估算

| 操作 | 时间 | 说明 |
|------|------|------|
| 准备文件 | 10秒 | 复制前端文件 |
| 清理旧容器 | 10秒 | 停止并删除 |
| 构建镜像 | 2-4分钟 | 下载依赖、构建 |
| 启动服务 | 30-40秒 | 容器启动、健康检查 |
| **总计** | **3-5分钟** | 完整部署 |

---

## ✅ 部署成功标志

运行 `docker compose ps` 看到：

```
NAME                            STATUS
memory-reconstruction-backend   Up (healthy)
memory-reconstruction-nginx     Up
```

访问 https://shangyu.icu 看到：

- ✅ 白色背景、现代 UI
- ✅ 左侧显示 "🧠 Memory Reconstruction"
- ✅ 中间显示 3 个快速示例卡片
- ✅ 可以正常发送消息并收到回复

---

## 🎉 恭喜！

你已成功部署 Memory Reconstruction Platform！

**接下来可以:**
- 🌐 访问 https://shangyu.icu 体验
- 📊 运行 `bash check-system.sh` 查看系统状态
- 📝 查看 `docker compose logs -f` 监控日志
- 📚 阅读 [README-PRODUCTION.md](README-PRODUCTION.md) 了解更多功能

---

**快速帮助:**
- 📖 完整文档: [README-PRODUCTION.md](README-PRODUCTION.md)
- 🔧 故障排除: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 📈 升级指南: [UPGRADE_GUIDE.md](UPGRADE_GUIDE.md)

---

<div align="center">

**Memory Reconstruction Platform v2.0**

[⬆ 回到顶部](#-快速部署指南)

</div>

