# 🚀 快速开始指南

## 5分钟快速启动

### 本地测试（开发环境）

#### Windows用户

1. **打开项目目录**
   ```cmd
   cd D:\yuanshi
   ```

2. **双击运行**
   ```cmd
   start.bat
   ```

3. **打开浏览器**
   - 自动打开或手动访问: `file:///D:/yuanshi/frontend/index.html`
   - 或使用本地服务器: `http://localhost:3000`

#### Linux/Mac用户

1. **打开终端**
   ```bash
   cd /path/to/yuanshi
   ```

2. **运行启动脚本**
   ```bash
   chmod +x start.sh
   ./start.sh
   ```

3. **打开浏览器**
   访问 `http://localhost:3000`

### 首次使用步骤

1. **安装依赖** （首次运行时自动安装）
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

2. **启动后端服务**
   ```bash
   python server.py
   ```
   
   看到以下信息表示成功：
   ```
   ✅ 数据库初始化完成
   🚀 启动服务器: http://0.0.0.0:8000
   ```

3. **打开前端页面**
   
   **方式一：直接打开HTML文件**
   ```
   双击 frontend/index.html
   ```
   
   **方式二：使用HTTP服务器（推荐）**
   ```bash
   cd frontend
   python -m http.server 3000
   ```
   
   然后访问: `http://localhost:3000`

4. **开始测试**
   - 点击"✨ 新建对话"
   - 输入测试内容，例如：
     ```
     解析这个JSON数据：{"name": "张三", "age": 25, "city": "北京"}
     ```
   - 点击发送或按Enter

## 功能测试示例

### 示例1：JSON数据解析
```
输入：解析以下JSON并提取关键信息：
{
  "user": {
    "id": 12345,
    "name": "李明",
    "email": "liming@example.com",
    "profile": {
      "age": 28,
      "city": "上海"
    }
  }
}
```

### 示例2：文本编码转换
```
输入：将"数据解构专家"这段文字转换为Base64编码
```

### 示例3：结构化信息提取
```
输入：从以下文本中提取结构化数据：
"订单号：20240125001，客户：王芳，金额：￥1,288.00，日期：2024年1月25日"
```

### 示例4：多层次数据编码
```
输入：对以下数据进行多层次编码分析：
原始数据：HTTPS://example.com/api?token=abc123&user=admin
```

### 示例5：复杂数据解构
```
输入：解构并分析以下日志数据：
[2024-01-25 14:30:15] INFO - User login successful | UserID: 1001 | IP: 192.168.1.100 | SessionID: xyz789
```

## 界面功能说明

### 主要功能

1. **新建对话** ✨
   - 点击左侧栏"新建对话"按钮
   - 开始全新的测试会话

2. **历史记录** 📚
   - 左侧栏显示所有历史会话
   - 点击会话卡片查看历史对话
   - 支持删除不需要的会话

3. **流式输出** 💬
   - 右上角开关控制
   - 开启：类似ChatGPT的逐字显示
   - 关闭：等待完整响应后显示

4. **显示思考** 🧠
   - 右上角开关控制
   - 开启：显示AI的推理过程
   - 适用于理解AI的决策逻辑

5. **输入框** ✍️
   - 支持多行输入
   - Enter键发送消息
   - 自动调整高度

## 测试API Key

项目已预配置您的API密钥：
- **API Key**: `sk-31d4c4895a6d4a959fa9f4ff029515ac`
- **App ID**: `6596ab6827f445f08abc4194be485bc1`

如需更改，编辑 `backend/.env` 文件。

⚠️ **注意**: 请勿将API密钥提交到公共代码仓库！

## 验证安装

运行测试脚本检查配置：

```bash
cd backend
python ../test_connection.py
```

如果看到：
```
✅ API连接成功!
✨ 所有测试通过!
```

说明配置正确，可以开始使用！

## 常见问题

### Q: 后端无法启动？

**A**: 检查Python版本和依赖
```bash
python --version  # 需要 3.8+
pip list | grep dashscope
pip install -r backend/requirements.txt
```

### Q: 前端无法连接后端？

**A**: 确认后端正在运行
```bash
# 测试后端
curl http://localhost:8000

# 检查端口
netstat -ano | findstr :8000  # Windows
lsof -i :8000                  # Linux/Mac
```

### Q: API调用失败？

**A**: 运行测试脚本诊断
```bash
python test_connection.py
```

查看具体错误信息，可能原因：
- API Key错误
- 网络连接问题
- 智能体ID不正确

### Q: 流式输出不工作？

**A**: 检查浏览器控制台
- F12 打开开发者工具
- 查看 Console 标签页
- 检查是否有CORS或网络错误

## 性能提示

1. **首次加载** 可能需要几秒钟初始化数据库
2. **流式输出** 响应更快，体验更好
3. **历史记录** 自动保存，无需手动操作
4. **多轮对话** 自动维护上下文

## 下一步

- ✅ 本地测试完成后，参考 [DEPLOYMENT.md](DEPLOYMENT.md) 部署到服务器
- ✅ 查看 [README.md](README.md) 了解更多功能
- ✅ 修改 `backend/server.py` 自定义API行为

## 获取帮助

遇到问题？

1. 查看后端日志输出
2. 检查浏览器控制台
3. 运行 `test_connection.py` 诊断
4. 查看 README.md 和 DEPLOYMENT.md

---

**开始测试吧！** 🎉

