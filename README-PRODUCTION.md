# 🧠 Memory Reconstruction Platform

> **AI驱动的智能记忆重构与分析平台 v2.0**

[![Status](https://img.shields.io/badge/status-production-success)](https://shangyu.icu)
[![Docker](https://img.shields.io/badge/docker-ready-blue)](https://www.docker.com/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## 📖 项目简介

Memory Reconstruction 是一个基于阿里百炼智能体的AI平台，专注于对用户输入信息进行多层次的编码和解析，以便于后续存储为向量数据。

### ✨ 核心特性

- 🤖 **智能对话**: 集成阿里百炼"数据解构专家"智能体
- 💬 **多轮对话**: 支持云端会话管理和历史记录
- ⚡ **流式输出**: 实时显示AI生成内容，减少等待时间
- 💾 **会话管理**: 智能标题生成，历史记录持久化
- 📤 **多格式导出**: 支持 Markdown、JSON、TXT 格式导出
- 🔍 **搜索功能**: 快速检索历史对话内容
- 🎨 **现代 UI**: 简洁优雅的白色主题，移动端优化
- 📱 **PWA 支持**: 可安装为桌面/移动应用
- 🐳 **Docker 部署**: 一键部署，零依赖烦恼

---

## 🚀 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- Linux/Mac/Windows (WSL2)

### 一键部署

```bash
# 1. 进入项目目录
cd /var/www/shangyu.icu/yuanshi

# 2. 运行部署脚本
bash deploy-production.sh
```

部署脚本会自动完成：
- ✅ 环境检查
- ✅ 前端文件准备
- ✅ 环境变量配置
- ✅ Docker 镜像构建
- ✅ 服务启动
- ✅ 健康检查

等待约 3-5 分钟，访问 https://shangyu.icu 即可使用！

---

## 📁 项目结构

```
yuanshi/
├── backend/                    # 后端服务
│   ├── server.py              # FastAPI 主程序
│   ├── requirements.txt       # Python 依赖
│   ├── .env                   # 环境变量配置
│   └── data/                  # SQLite 数据库目录
├── frontend/                   # 前端文件
│   ├── index.html             # 主页面（生产版本）
│   ├── index-optimized.html   # 优化版源文件
│   └── manifest.json          # PWA 配置
├── deploy/                     # 部署配置
│   └── nginx-docker.conf      # Nginx 配置
├── docker-compose.yml          # Docker Compose 配置
├── Dockerfile                  # Docker 镜像定义
├── deploy-production.sh        # 生产部署脚本
├── check-system.sh            # 健康检查脚本
├── TROUBLESHOOTING.md         # 故障排除指南
└── README-PRODUCTION.md       # 本文件
```

---

## 🛠️ 技术栈

### 后端
- **框架**: FastAPI 0.109.0
- **AI SDK**: DashScope 1.20.11 (阿里百炼)
- **数据库**: SQLite + aiosqlite
- **服务器**: Uvicorn
- **语言**: Python 3.11

### 前端
- **框架**: Vue 3 (Composition API)
- **HTTP 客户端**: Axios
- **Markdown**: Marked.js
- **代码高亮**: Highlight.js
- **样式**: 原生 CSS (CSS Variables)

### 部署
- **容器**: Docker + Docker Compose
- **反向代理**: Nginx 1.25-alpine
- **网络**: Docker Bridge Network
- **持久化**: Docker Volumes

---

## 🔧 管理命令

### 基本操作

```bash
# 查看服务状态
docker compose ps

# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 查看实时日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f backend
docker compose logs -f nginx
```

### 健康检查

```bash
# 运行健康检查脚本
bash check-system.sh

# 手动测试
curl http://localhost/                    # 前端
curl http://localhost:8000/               # 后端直连
curl http://localhost/api/sessions        # API 代理
```

### 更新部署

```bash
# 拉取最新代码
git pull

# 重新部署
bash deploy-production.sh

# 或手动步骤
cp frontend/index-optimized.html frontend/index.html
docker compose down
docker compose build --no-cache
docker compose up -d
```

---

## ⚙️ 配置说明

### 环境变量 (`backend/.env`)

```env
# 阿里百炼 API 配置
DASHSCOPE_API_KEY=sk-31d4c4895a6d4a959fa9f4ff029515ac
DASHSCOPE_APP_ID=6596ab6827f445f08abc4194be485bc1

# 服务器配置
HOST=0.0.0.0
PORT=8000

# 数据库配置
DATABASE_PATH=./data/sessions.db
```

### Docker Compose 配置

```yaml
services:
  backend:
    ports:
      - "8000:8000"         # 后端 API 端口
    volumes:
      - ./backend/data:/app/data        # 数据持久化
      - ./backend/.env:/app/.env:ro     # 环境变量
  
  nginx:
    ports:
      - "80:80"             # HTTP
      - "443:443"           # HTTPS（需配置证书）
    volumes:
      - ./frontend:/usr/share/nginx/html:ro   # 前端文件
      - ./ssl:/etc/nginx/ssl:ro               # SSL 证书
```

### Nginx 配置要点

- **静态文件**: 服务于 `/usr/share/nginx/html`
- **API 代理**: `/api/*` → `http://backend:8000/api/*`
- **SSE 支持**: 流式响应优化配置
- **Gzip 压缩**: 自动压缩文本资源
- **缓存策略**: HTML 不缓存，静态资源长期缓存

---

## 🌐 API 端点

### 会话管理

```bash
# 获取所有会话
GET /api/sessions

# 发送消息（流式）
POST /api/send
Content-Type: application/json
{
  "session_id": "xxx",
  "prompt": "你好"
}

# 删除会话
DELETE /api/sessions/{session_id}

# 重命名会话
PUT /api/sessions/{session_id}/rename
{
  "title": "新标题"
}
```

### 高级功能

```bash
# 搜索历史消息
GET /api/search?q=关键词

# 导出会话
GET /api/export/{session_id}?format=markdown

# 统计信息
GET /api/stats
```

---

## 📊 监控与日志

### 日志位置

```bash
# Docker 日志
docker compose logs --tail 100 backend
docker compose logs --tail 100 nginx

# Nginx 访问日志（容器内）
docker exec memory-reconstruction-nginx tail -f /var/log/nginx/access.log

# Nginx 错误日志（容器内）
docker exec memory-reconstruction-nginx tail -f /var/log/nginx/error.log
```

### 资源监控

```bash
# 查看容器资源使用
docker stats

# 查看磁盘使用
docker system df
du -sh backend/data/
```

---

## 🔒 安全配置

### 防火墙设置

```bash
# 开放 HTTP/HTTPS 端口
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 阿里云安全组

在阿里云控制台配置：

1. 入方向规则:
   - 端口 `80/80` (HTTP)
   - 端口 `443/443` (HTTPS)
   - 授权对象 `0.0.0.0/0`

### HTTPS 配置（可选）

```bash
# 1. 获取 SSL 证书（Let's Encrypt）
sudo certbot certonly --standalone -d shangyu.icu

# 2. 复制证书到项目
sudo cp /etc/letsencrypt/live/shangyu.icu/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/shangyu.icu/privkey.pem ssl/

# 3. 修改 Nginx 配置
# 取消 deploy/nginx-docker.conf 中 HTTPS 部分的注释

# 4. 重启 Nginx
docker compose restart nginx
```

---

## 🐛 故障排除

### 常见问题

#### 1. 404 Not Found

```bash
# 确保使用优化版本
cp frontend/index-optimized.html frontend/index.html
docker compose restart nginx
```

#### 2. 后端重启

```bash
# 查看错误日志
docker compose logs --tail 50 backend

# 重新构建
docker compose build --no-cache backend
docker compose up -d
```

#### 3. 外网无法访问

检查阿里云安全组，确保开放了 80/443 端口。

更多问题请查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 📈 性能优化

### 前端优化

- ✅ CDN 加载核心库
- ✅ Gzip 压缩
- ✅ 静态资源缓存
- ✅ 骨架屏加载
- ✅ 虚拟滚动（长列表）

### 后端优化

- ✅ 异步数据库操作
- ✅ 流式响应
- ✅ 连接池管理
- ✅ 健康检查

### 部署优化

- ✅ 多阶段 Docker 构建
- ✅ 镜像层缓存
- ✅ 日志轮转
- ✅ 资源限制

---

## 📝 开发指南

### 本地开发

```bash
# 后端开发
cd backend
pip install -r requirements.txt
cp .env.example .env  # 配置环境变量
python server.py

# 前端开发
cd frontend
# 直接在浏览器打开 index-optimized.html
# 或使用简单的 HTTP 服务器
python -m http.server 8080
```

### 代码规范

- Python: PEP 8
- JavaScript: ESLint (Airbnb)
- HTML/CSS: Prettier

### 测试

```bash
# API 测试
curl -X POST http://localhost:8000/api/send \
  -H "Content-Type: application/json" \
  -d '{"prompt": "测试消息"}'

# 前端测试
# 打开浏览器开发者工具，检查控制台无错误
```

---

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 📞 联系方式

- **网站**: https://shangyu.icu
- **邮箱**: admin@shangyu.icu
- **问题反馈**: [GitHub Issues](https://github.com/yourname/memory-reconstruction/issues)

---

## 🙏 致谢

- [阿里百炼](https://bailian.console.aliyun.com/) - AI 能力提供
- [FastAPI](https://fastapi.tiangolo.com/) - 高性能 Web 框架
- [Vue.js](https://vuejs.org/) - 渐进式 JavaScript 框架
- [Docker](https://www.docker.com/) - 容器化平台

---

## 📚 相关文档

- [部署指南](DEPLOY_OPTIMIZED.md)
- [故障排除](TROUBLESHOOTING.md)
- [升级指南](UPGRADE_GUIDE.md)
- [优化计划](OPTIMIZATION_PLAN.md)

---

**最后更新:** 2025-10-26  
**版本:** 2.0.0  
**状态:** ✅ Production Ready

---

<div align="center">

**Made with ❤️ by Memory Reconstruction Team**

[⬆ 回到顶部](#-memory-reconstruction-platform)

</div>

