# 💻 本地开发指南

## 🎯 目标

在本地完整测试系统，确认无误后再部署到服务器。

---

## 📋 前置要求

### Windows 系统需要安装：

1. **Docker Desktop for Windows**
   - 下载: https://www.docker.com/products/docker-desktop/
   - 安装后启动 Docker Desktop
   - 确保 WSL 2 已启用

2. **Git for Windows**（可选，用于版本管理）
   - 下载: https://git-scm.com/download/win

3. **VSCode**（推荐）
   - 下载: https://code.visualstudio.com/

---

## 🚀 本地快速启动

### 方法 1: 使用 Docker（推荐）⭐

#### 步骤 1: 确保 Docker Desktop 运行中

```powershell
# 检查 Docker 是否运行
docker --version
docker compose version
```

#### 步骤 2: 准备环境

在项目根目录（`D:\yuanshi`）打开 **PowerShell** 或 **终端**：

```powershell
# 1. 准备前端文件
Copy-Item frontend\index-optimized.html frontend\index.html -Force
Copy-Item PWA-manifest.json frontend\manifest.json -Force -ErrorAction SilentlyContinue

# 2. 创建后端环境配置
$envContent = @"
DASHSCOPE_API_KEY=sk-31d4c4895a6d4a959fa9f4ff029515ac
DASHSCOPE_APP_ID=6596ab6827f445f08abc4194be485bc1
HOST=0.0.0.0
PORT=8000
DATABASE_PATH=./data/sessions.db
"@
$envContent | Out-File -FilePath backend\.env -Encoding utf8

# 3. 创建数据目录
New-Item -ItemType Directory -Force -Path backend\data
New-Item -ItemType Directory -Force -Path ssl

# 4. 构建并启动服务
docker compose up -d --build

# 5. 等待服务启动（30秒）
Write-Host "⏳ 等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 6. 查看状态
Write-Host "`n========== 📊 服务状态 ==========" -ForegroundColor Cyan
docker compose ps

# 7. 查看日志
Write-Host "`n========== 📝 服务日志 ==========" -ForegroundColor Cyan
docker compose logs --tail 20
```

#### 步骤 3: 测试访问

打开浏览器访问：
- 🌐 **前端**: http://localhost
- 🔧 **后端 API**: http://localhost:8000

---

### 方法 2: 使用 CMD/批处理脚本

我为你创建一个 Windows 批处理脚本。

---

## 🧪 本地测试清单

### 1️⃣ 基础功能测试

**在浏览器中测试：**

- [ ] 页面正常加载（白色背景）
- [ ] 左侧显示 "🧠 Memory Reconstruction"
- [ ] 中间显示 3 个示例卡片
- [ ] 点击 "新建对话" 可以创建会话
- [ ] 发送消息能收到 AI 回复
- [ ] 回复以流式方式显示
- [ ] 会话标题自动生成
- [ ] 可以切换不同会话
- [ ] 可以删除会话
- [ ] 可以重命名会话

### 2️⃣ UI/UX 测试

- [ ] 代码块有语法高亮
- [ ] 代码块有复制按钮
- [ ] 滚动流畅
- [ ] 按 Cmd/Ctrl+K 可新建对话
- [ ] 按 Esc 可关闭侧边栏（移动端）

### 3️⃣ 移动端测试

打开浏览器开发者工具（F12）→ 切换到移动设备模式：

- [ ] 页面适配良好
- [ ] 右下角显示菜单按钮（≡）
- [ ] 点击菜单可展开侧边栏
- [ ] 输入框大小合适
- [ ] 虚拟键盘不遮挡内容

### 4️⃣ API 测试

在 PowerShell 中测试：

```powershell
# 测试后端健康检查
Invoke-WebRequest -Uri "http://localhost:8000/" | Select-Object StatusCode, Content

# 测试前端
Invoke-WebRequest -Uri "http://localhost/" | Select-Object StatusCode

# 测试 API 代理
Invoke-WebRequest -Uri "http://localhost/api/sessions" | Select-Object StatusCode, Content
```

---

## 🔧 常用命令

### Docker 容器管理

```powershell
# 查看运行状态
docker compose ps

# 查看日志（实时）
docker compose logs -f

# 查看特定服务日志
docker compose logs -f backend
docker compose logs -f nginx

# 重启服务
docker compose restart

# 停止服务
docker compose down

# 完全清理并重启
docker compose down -v
docker compose up -d --build
```

### 快速更新

```powershell
# 只更新前端（3秒）
Copy-Item frontend\index-optimized.html frontend\index.html -Force
docker compose restart nginx

# 更新后端（30-60秒）
docker compose build backend
docker compose up -d backend

# 完全重建（3-5分钟）
docker compose down
docker compose up -d --build
```

---

## 📊 性能监控

### 查看资源使用

```powershell
# 查看容器资源占用
docker stats

# 查看容器详情
docker compose ps -a
```

---

## 🐛 本地调试

### 进入容器调试

```powershell
# 进入后端容器
docker compose exec backend bash

# 进入 Nginx 容器
docker compose exec nginx sh

# 查看后端 Python 环境
docker compose exec backend python --version
docker compose exec backend pip list
```

### 测试 DashScope SDK

```powershell
# 在后端容器中测试
docker compose exec backend python -c "from dashscope import Application; print('DashScope SDK 导入成功')"
```

### 查看日志文件

```powershell
# 后端日志
docker compose logs backend --tail 100

# Nginx 访问日志
docker compose exec nginx tail -f /var/log/nginx/access.log

# Nginx 错误日志
docker compose exec nginx tail -f /var/log/nginx/error.log
```

---

## 🔄 开发工作流

### 典型的开发流程：

```
1. 修改代码
   ↓
2. 本地测试
   ↓
3. 确认无误
   ↓
4. 提交到 Git
   ↓
5. 推送到 GitHub
   ↓
6. 服务器拉取更新
   ↓
7. 服务器部署
```

### 具体步骤：

#### 1. 修改代码（本地）

```powershell
# 编辑文件
code frontend\index-optimized.html
# 或
code backend\server.py
```

#### 2. 本地测试

```powershell
# 如果改了前端
Copy-Item frontend\index-optimized.html frontend\index.html -Force
docker compose restart nginx

# 如果改了后端
docker compose build backend
docker compose up -d backend

# 浏览器测试
start http://localhost
```

#### 3. 确认无误后提交

```bash
# 使用 Git Bash
git add .
git commit -m "描述你的修改"
git push origin main
```

#### 4. 服务器部署

```bash
# SSH 到服务器
ssh admin@8.137.51.166

# 更新代码
cd /var/www/shangyu.icu/yuanshi
git pull

# 智能更新
bash smart-update.sh
```

---

## 📝 本地配置文件

### backend/.env（本地开发）

```env
# 使用相同的 API 配置
DASHSCOPE_API_KEY=sk-31d4c4895a6d4a959fa9f4ff029515ac
DASHSCOPE_APP_ID=6596ab6827f445f08abc4194be485bc1
HOST=0.0.0.0
PORT=8000
DATABASE_PATH=./data/sessions.db
```

### 本地数据库

本地测试会在 `backend/data/sessions.db` 创建数据库。

**注意：** 这是本地测试数据，不会影响服务器。

---

## 🚨 常见问题

### Q: Docker Desktop 无法启动

**解决：**
1. 确保 WSL 2 已安装和启用
2. 在 Docker Desktop 设置中启用 WSL 2
3. 重启电脑

### Q: 端口被占用

**错误：** `Error: Port 80 is already allocated`

**解决：**
```powershell
# 查找占用端口的进程
netstat -ano | findstr :80

# 停止 IIS（如果在运行）
net stop was /y

# 或者修改端口
# 编辑 docker-compose.yml，将 80:80 改为 8080:80
# 然后访问 http://localhost:8080
```

### Q: Docker 构建很慢

**解决：**
- 等待首次构建完成（会下载依赖）
- 之后的构建会使用缓存，快很多
- 可以配置 Docker Desktop 使用国内镜像源

### Q: 前端无法连接后端

**检查：**
```powershell
# 确保两个容器都在运行
docker compose ps

# 测试后端
Invoke-WebRequest http://localhost:8000/

# 查看 Nginx 日志
docker compose logs nginx
```

---

## 🎯 本地 vs 生产环境

| 特性 | 本地开发 | 生产环境 |
|------|----------|----------|
| 域名 | localhost | shangyu.icu |
| 端口 | 80, 8000 | 80, 443 |
| HTTPS | ❌ | ✅ |
| 数据库 | 本地测试 | 持久化 |
| 日志 | Docker logs | 文件 + Docker logs |
| 性能 | 开发模式 | 生产优化 |

---

## ✅ 准备部署到服务器

### 检查清单

部署前确认：

- [ ] 本地所有功能测试通过
- [ ] 没有控制台错误
- [ ] 移动端适配正常
- [ ] API 调用正常
- [ ] 代码已提交到 Git
- [ ] Git 已推送到远程仓库

### 部署到服务器

```bash
# 1. SSH 登录
ssh admin@8.137.51.166

# 2. 更新代码
cd /var/www/shangyu.icu/yuanshi
git pull

# 3. 智能更新（自动检测变化）
bash smart-update.sh

# 4. 验证
bash check-system.sh

# 5. 浏览器访问
# https://shangyu.icu
```

---

## 🔗 相关文档

- 📖 [START_HERE.md](START_HERE.md) - 快速开始
- 🚀 [QUICK_DEPLOY.md](QUICK_DEPLOY.md) - 快速部署
- 🔧 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 问题排查
- 🔄 [WHY_REBUILD.md](WHY_REBUILD.md) - 更新策略

---

<div align="center">

**本地开发 → 测试 → 部署**

**安全、高效、专业** 🚀

[⬆ 回到顶部](#-本地开发指南)

</div>

