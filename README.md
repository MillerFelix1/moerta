# 🔍 数据解构专家 - 测试平台

一个简洁高级的Web应用，用于测试阿里百炼智能体"数据解构专家"的多层次编码与解析能力。

## ✨ 特性

- 🎨 **现代化UI设计** - 简洁高级的深色主题界面
- 💬 **实时流式输出** - 类似ChatGPT的打字机效果
- 🧠 **思考过程展示** - 可选展示AI的推理过程
- 💾 **历史记录管理** - SQLite存储，支持多会话管理
- 🔄 **多轮对话支持** - 智能上下文记忆
- 🔍 **消息搜索** - 快速检索历史对话
- 📱 **响应式设计** - 完美适配各种屏幕尺寸

## 🏗️ 技术栈

**后端:**
- FastAPI - 高性能异步Web框架
- DashScope SDK - 阿里百炼官方SDK
- SQLite + aiosqlite - 轻量级数据库
- Python 3.8+

**前端:**
- Vue 3 - 渐进式JavaScript框架
- Axios - HTTP客户端
- Marked - Markdown渲染
- 原生CSS - 无需构建工具

## 📦 安装部署

### 1. 环境要求

- Python 3.8 或更高版本
- pip 包管理器

### 2. 安装步骤

```bash
# 克隆项目（如果是从git）或进入项目目录
cd yuanshi

# 安装Python依赖
cd backend
pip install -r requirements.txt

# 返回项目根目录
cd ..
```

### 3. 配置环境变量

后端配置文件 `backend/.env` 已包含您的API密钥：

```env
DASHSCOPE_API_KEY=sk-31d4c4895a6d4a959fa9f4ff029515ac
APP_ID=6596ab6827f445f08abc4194be485bc1
HOST=0.0.0.0
PORT=8000
DATABASE_PATH=./data/history.db
```

⚠️ **安全提示**: 生产环境请妥善保管API密钥，不要提交到版本控制系统。

### 4. 启动服务

#### 方式一：使用启动脚本（推荐）

**Windows:**
```bash
./start.bat
```

**Linux/Mac:**
```bash
chmod +x start.sh
./start.sh
```

#### 方式二：手动启动

```bash
# 启动后端服务
cd backend
python server.py
```

然后在浏览器访问前端页面：
```
file:///D:/yuanshi/frontend/index.html
```

或者使用简单的HTTP服务器：
```bash
# Python 3
cd frontend
python -m http.server 3000

# 访问: http://localhost:3000
```

### 5. 服务器部署

#### 5.1 使用systemd（Linux）

创建服务文件 `/etc/systemd/system/data-expert.service`:

```ini
[Unit]
Description=Data Expert Test Platform
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/yuanshi/backend
Environment="PATH=/usr/bin:/usr/local/bin"
ExecStart=/usr/bin/python3 server.py
Restart=always

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable data-expert
sudo systemctl start data-expert
sudo systemctl status data-expert
```

#### 5.2 使用Nginx反向代理

配置文件 `/etc/nginx/sites-available/shangyu.icu`:

```nginx
server {
    listen 80;
    server_name shangyu.icu;

    # 前端静态文件
    location / {
        root /path/to/yuanshi/frontend;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # 流式响应配置
        proxy_buffering off;
        proxy_read_timeout 300s;
    }
}
```

启用站点：
```bash
sudo ln -s /etc/nginx/sites-available/shangyu.icu /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### 5.3 配置SSL证书（推荐）

```bash
# 使用Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d shangyu.icu
```

#### 5.4 防火墙配置

```bash
# 允许HTTP和HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp  # 如果直接访问后端
sudo ufw enable
```

## 📖 使用指南

### 基本操作

1. **新建对话**: 点击左侧 "✨ 新建对话" 按钮
2. **发送消息**: 在底部输入框输入内容，按Enter或点击"发送"
3. **查看历史**: 左侧列表显示所有历史会话
4. **切换会话**: 点击会话卡片加载历史对话
5. **删除会话**: 选中会话后点击"删除"按钮

### 高级功能

- **流式输出**: 右上角开关控制是否实时显示生成过程
- **显示思考**: 开启后可查看AI的推理过程（需智能体支持）
- **多轮对话**: 自动维护上下文，支持连续对话

### 测试示例

```
示例1: 数据解析
输入: 解析这段JSON: {"user": {"name": "张三", "age": 25}}

示例2: 编码转换
输入: 将"Hello World"转换为Base64编码

示例3: 结构化提取
输入: 从"今天天气不错，温度25度"中提取结构化信息
```

## 🔧 API接口文档

### 对话接口
```
POST /api/chat
Content-Type: application/json

{
  "prompt": "你的问题",
  "session_id": "可选的会话ID",
  "stream": true,
  "incremental_output": true,
  "has_thoughts": false
}
```

### 会话管理
```
GET  /api/sessions              # 获取所有会话
GET  /api/sessions/{session_id} # 获取会话详情
PUT  /api/sessions/{session_id} # 更新会话标题
DELETE /api/sessions/{session_id} # 删除会话
```

### 搜索接口
```
GET /api/search?keyword=关键词   # 搜索历史消息
```

## 📁 项目结构

```
yuanshi/
├── backend/                # 后端服务
│   ├── server.py          # FastAPI主服务
│   ├── database.py        # 数据库操作
│   ├── requirements.txt   # Python依赖
│   └── data/              # SQLite数据库（自动创建）
├── frontend/              # 前端页面
│   └── index.html         # 单页面应用
├── .gitignore            # Git忽略文件
├── README.md             # 项目文档
├── start.sh              # Linux/Mac启动脚本
└── start.bat             # Windows启动脚本
```

## 🐛 故障排除

### 问题1: 无法连接后端API

**解决方案:**
- 检查后端服务是否运行: `curl http://localhost:8000`
- 查看防火墙设置
- 检查前端 `index.html` 中的 `apiBaseUrl` 配置

### 问题2: API Key错误

**解决方案:**
- 检查 `backend/.env` 文件中的配置
- 确认API Key有效且未过期
- 访问阿里云控制台验证密钥

### 问题3: 数据库权限错误

**解决方案:**
```bash
# 确保数据目录存在且有写权限
mkdir -p backend/data
chmod 755 backend/data
```

### 问题4: 流式输出不工作

**解决方案:**
- 检查Nginx配置中的 `proxy_buffering off`
- 确认浏览器支持SSE（Server-Sent Events）
- 查看浏览器控制台错误信息

## 🔐 安全建议

1. ✅ 使用HTTPS加密传输
2. ✅ API Key使用环境变量，不要硬编码
3. ✅ 配置CORS只允许特定域名
4. ✅ 定期备份数据库
5. ✅ 使用防火墙限制访问
6. ✅ 启用Nginx访问日志监控

## 📊 性能优化

- 数据库索引已优化查询速度
- 使用异步操作提升并发性能
- 流式输出减少等待时间
- 静态资源使用CDN加速

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

本项目仅供学习和测试使用。

## 📮 联系方式

- 网站: https://shangyu.icu
- 服务器: 8.137.51.166

---

**享受测试！** 🚀

