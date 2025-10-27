# 🔄 智能更新策略

## 📚 理解 Docker 的文件系统

### 两种方式加载文件

```
┌─────────────────────────────────────────┐
│          Docker 容器                     │
├─────────────────────────────────────────┤
│                                         │
│  📦 镜像内置文件（需要重建）             │
│  ├─ Python 代码 (server.py)            │
│  ├─ Python 依赖 (requirements.txt)     │
│  └─ 系统文件                            │
│                                         │
│  💾 卷挂载文件（实时生效，无需重建）     │
│  ├─ 前端文件 (frontend/)               │
│  ├─ 配置文件 (.env)                     │
│  ├─ Nginx 配置 (nginx-docker.conf)     │
│  └─ 数据库 (data/)                      │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🎯 核心原则

### ✅ **镜像构建的文件**（在 Dockerfile 中 COPY 的）
```dockerfile
# Dockerfile
COPY backend/requirements.txt .    # ← 进入镜像
RUN pip install -r requirements.txt
COPY backend/ .                    # ← 进入镜像（server.py等）
```
**这些文件改变 = 必须重建镜像**

### 💾 **卷挂载的文件**（在 docker-compose.yml 中 volumes 的）
```yaml
# docker-compose.yml
volumes:
  - ./frontend:/usr/share/nginx/html:ro       # ← 卷挂载
  - ./backend/.env:/app/.env:ro               # ← 卷挂载
  - ./deploy/nginx-docker.conf:/.../default.conf:ro  # ← 卷挂载
```
**这些文件改变 = 只需重启容器**

---

## 📊 不同场景的更新方式

### 场景 1: 只修改了前端文件 ⚡ **最快**

**文件类型：** `frontend/index.html`, `frontend/manifest.json`

**更新命令：**
```bash
# 方法 1: 使用智能脚本（推荐）
bash smart-update.sh

# 方法 2: 手动更新
cp frontend/index-optimized.html frontend/index.html
docker compose restart nginx

# 时间: 3-5 秒
```

**为什么快？**
- ✅ 前端文件是卷挂载的
- ✅ 文件在宿主机上，容器内实时可见
- ✅ 只需重启 Nginx 重新加载文件
- ❌ 不需要重建镜像

---

### 场景 2: 只修改了后端代码 🔨 **需要重建**

**文件类型：** `backend/server.py`, `backend/database.py`

**更新命令：**
```bash
# 方法 1: 智能更新（推荐）
bash smart-update.sh

# 方法 2: 手动重建后端
docker compose build backend
docker compose up -d backend

# 时间: 2-4 分钟（首次）
# 时间: 30-60 秒（有缓存）
```

**为什么需要时间？**
- 🔨 后端代码被 COPY 进镜像
- 📦 需要重新构建镜像层
- 但 Docker 会使用缓存加速：
  - ✅ Python 基础镜像已缓存
  - ✅ 系统依赖已缓存
  - ✅ Python 包已缓存（如果 requirements.txt 未变）

---

### 场景 3: 修改了 Python 依赖 📦 **最慢**

**文件类型：** `backend/requirements.txt`

**更新命令：**
```bash
# 需要完全重建（安装新依赖）
docker compose build --no-cache backend
docker compose up -d backend

# 时间: 3-5 分钟
```

**为什么慢？**
- 📦 需要重新下载和安装 Python 包
- 🔨 依赖变化导致后续层缓存失效

---

### 场景 4: 修改了 Nginx 配置 ⚡ **快速**

**文件类型：** `deploy/nginx-docker.conf`

**更新命令：**
```bash
# 只需重启 Nginx
docker compose restart nginx

# 时间: 3 秒
```

**为什么快？**
- ✅ Nginx 配置是卷挂载的
- ✅ 重启时自动加载新配置

---

### 场景 5: 修改了环境变量 ⚡ **快速**

**文件类型：** `backend/.env`

**更新命令：**
```bash
# 重启后端
docker compose restart backend

# 时间: 5-10 秒
```

---

### 场景 6: 修改了 docker-compose.yml 🔄 **中等**

**更新命令：**
```bash
# 应用新配置
docker compose up -d

# 时间: 10-30 秒
# Docker 会自动检测变化并只重启受影响的服务
```

---

## 🚀 推荐的更新工作流

### 日常开发（频繁更新）

```bash
# 1. 修改文件
nano frontend/index-optimized.html

# 2. 使用智能脚本（自动检测变化）
bash smart-update.sh

# 3. 测试
curl http://localhost/
```

### 功能更新（后端+前端）

```bash
# 1. 拉取最新代码
git pull

# 2. 智能更新
bash smart-update.sh

# 3. 检查状态
docker compose ps
```

### 大版本升级

```bash
# 1. 备份数据
cp -r backend/data backend/data.backup

# 2. 完全重建
docker compose down
docker compose build --no-cache
docker compose up -d

# 3. 验证
bash check-system.sh
```

---

## 💡 优化技巧

### 技巧 1: 分离不常变化的依赖

**当前 Dockerfile:**
```dockerfile
COPY backend/requirements.txt .
RUN pip install -r requirements.txt  # ← 缓存层
COPY backend/ .                      # ← 代码层
```

**优点：**
- ✅ `requirements.txt` 不变时，pip install 层被缓存
- ✅ 只有代码改变时才重新 COPY

### 技巧 2: 使用 .dockerignore

```bash
# .dockerignore
__pycache__/
*.pyc
*.pyo
.git/
node_modules/
.env
data/
```

**优点：**
- ✅ 减少构建上下文大小
- ✅ 加快构建速度
- ✅ 避免不必要的缓存失效

### 技巧 3: 多阶段构建（未来优化）

```dockerfile
# 构建阶段
FROM python:3.11-slim AS builder
RUN pip install --user -r requirements.txt

# 运行阶段
FROM python:3.11-slim
COPY --from=builder /root/.local /root/.local
```

**优点：**
- ✅ 更小的最终镜像
- ✅ 更好的缓存利用

---

## 📊 性能对比

| 场景 | 传统方式 | 智能方式 | 节省时间 |
|------|---------|---------|----------|
| 前端更新 | 4分钟（重建全部） | 5秒（只重启Nginx） | **98%** ⬇️ |
| 后端代码更新 | 4分钟（无缓存） | 1分钟（有缓存） | **75%** ⬇️ |
| 配置更新 | 4分钟 | 5秒 | **98%** ⬇️ |
| 依赖更新 | 5分钟 | 5分钟 | 0% |

---

## 🔍 如何判断是否需要重建？

### 检查当前镜像

```bash
# 查看镜像创建时间
docker images memory-reconstruction-backend

# 查看镜像历史
docker history memory-reconstruction-backend:latest
```

### 使用智能脚本

```bash
# 自动检测并更新
bash smart-update.sh
```

脚本会：
1. 计算后端文件的哈希值
2. 与上次构建时的哈希对比
3. 只在必要时重建

---

## 📝 最佳实践

### ✅ 推荐做法

1. **日常开发**：使用 `smart-update.sh`
2. **前端修改**：只重启 Nginx
3. **配置修改**：只重启相关服务
4. **定期清理**：`docker system prune -f`

### ❌ 避免的做法

1. **不要**每次都 `--no-cache`（浪费时间）
2. **不要**修改前端就重建镜像（无意义）
3. **不要**频繁清理镜像缓存（失去缓存优势）

---

## 🎯 快速参考

### 我改了什么？应该怎么做？

```bash
# 前端文件 (index.html, manifest.json)
→ cp frontend/index-optimized.html frontend/index.html && docker compose restart nginx

# 后端代码 (server.py, database.py)
→ docker compose build backend && docker compose up -d backend

# Python 依赖 (requirements.txt)
→ docker compose build --no-cache backend && docker compose up -d backend

# Nginx 配置 (nginx-docker.conf)
→ docker compose restart nginx

# 环境变量 (.env)
→ docker compose restart backend

# Docker Compose 配置
→ docker compose up -d

# 不确定？
→ bash smart-update.sh
```

---

## 🔧 故障排除

### 问题：明明改了代码，但没生效

**原因：** Docker 使用了旧的缓存层

**解决：**
```bash
# 强制重建
docker compose build --no-cache backend
docker compose up -d
```

### 问题：构建很慢

**原因：** 可能的原因
1. 网络慢（下载包）
2. 缓存被清理
3. 依赖文件改变

**解决：**
```bash
# 使用国内镜像源
# 在 Dockerfile 中添加：
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

### 问题：镜像越来越大

**解决：**
```bash
# 清理未使用的镜像
docker image prune -a

# 查看镜像大小
docker images
```

---

## 📚 总结

### 关键要点

1. **卷挂载的文件** = 修改后只需重启容器（秒级）
2. **镜像内的文件** = 修改后需要重建镜像（分钟级）
3. **使用智能脚本** = 自动判断，最优更新
4. **理解 Docker 缓存** = 加快构建速度

### 时间对比

| 更新方式 | 时间 | 适用场景 |
|----------|------|----------|
| 只重启服务 | 3-5秒 | 前端、配置 |
| 重建（有缓存） | 30-60秒 | 后端代码 |
| 完全重建 | 3-5分钟 | 依赖变化 |

---

<div align="center">

**使用 `smart-update.sh` 实现最优更新！**

[⬆ 回到顶部](#-智能更新策略)

</div>

