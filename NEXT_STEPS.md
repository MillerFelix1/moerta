# 🎯 下一步操作指南

## ✅ 项目已完成！

恭喜！您的"数据解构专家测试平台"已经完全配置好了。

## 📍 现在可以做什么？

### 选项1️⃣: 本地快速测试（推荐先做这个）

```bash
# 1. 打开命令行，进入项目目录
cd D:\yuanshi

# 2. 运行测试脚本，验证API配置
python test_connection.py

# 3. 如果测试通过，启动服务
start.bat
```

**然后打开浏览器访问:**
- 直接双击打开: `D:\yuanshi\frontend\index.html`
- 或使用本地服务器: http://localhost:3000

### 选项2️⃣: 部署到服务器 shangyu.icu

```bash
# 1. 上传项目到服务器
scp -r D:\yuanshi root@8.137.51.166:/var/www/shangyu.icu

# 2. SSH连接到服务器
ssh root@8.137.51.166

# 3. 运行自动部署脚本
cd /var/www/shangyu.icu
sudo bash deploy/deploy.sh

# 4. 按照提示完成部署
```

**然后访问:** https://shangyu.icu

## 📖 重要文档参考

| 文档 | 用途 |
|------|------|
| `QUICKSTART.md` | 5分钟快速上手 |
| `README.md` | 完整项目文档 |
| `DEPLOYMENT.md` | 详细部署指南 |
| `PROJECT_SUMMARY.md` | 项目功能总结 |
| `examples/test_cases.json` | 12个测试用例 |

## 🧪 测试用例快速开始

打开网页后，可以尝试以下测试：

**测试1 - JSON解析:**
```
解析以下JSON数据：
{"user": {"name": "张三", "age": 25, "city": "北京"}}
```

**测试2 - 编码转换:**
```
将"数据解构专家"转换为Base64编码
```

**测试3 - 结构化提取:**
```
从以下文本中提取信息：
订单号：20240125001，客户：王芳，金额：￥1,288.00
```

更多测试用例请查看 `examples/test_cases.json`

## 🔍 验证清单

在正式使用前，请确认：

- [ ] API连接测试通过 (`python test_connection.py`)
- [ ] 后端服务正常启动
- [ ] 前端页面可以访问
- [ ] 可以发送消息并收到回复
- [ ] 历史记录能正常保存和加载
- [ ] 流式输出工作正常

## 🆘 遇到问题？

### 后端无法启动
```bash
# 检查Python版本
python --version  # 需要 3.8+

# 重新安装依赖
cd backend
pip install -r requirements.txt
```

### API调用失败
```bash
# 运行诊断脚本
python test_connection.py

# 检查.env配置（注意：.env文件可能被gitignore阻止创建）
# 可以手动创建 backend/.env 文件，内容如下：
```

**backend/.env 内容:**
```env
DASHSCOPE_API_KEY=sk-31d4c4895a6d4a959fa9f4ff029515ac
APP_ID=6596ab6827f445f08abc4194be485bc1
HOST=0.0.0.0
PORT=8000
DATABASE_PATH=./data/history.db
```

### 前端无法连接
- 确认后端已启动: `curl http://localhost:8000`
- 检查浏览器控制台 (F12) 的错误信息
- 确认防火墙没有阻止8000端口

## 📁 项目文件说明

```
yuanshi/
├── backend/           后端服务目录
│   ├── server.py     FastAPI主服务 (核心!)
│   ├── database.py   数据库操作
│   └── requirements.txt  Python依赖
├── frontend/         前端界面
│   └── index.html    单页面应用 (打开即用!)
├── deploy/           服务器部署配置
├── examples/         测试用例
├── start.bat         Windows启动脚本
├── start.sh          Linux/Mac启动脚本
└── test_connection.py 测试脚本 (先运行这个!)
```

## 🎯 推荐流程

**第一次使用建议按此顺序:**

1. ✅ **测试API连接**
   ```bash
   python test_connection.py
   ```

2. ✅ **本地启动服务**
   ```bash
   start.bat  # Windows
   ./start.sh # Linux/Mac
   ```

3. ✅ **打开前端页面**
   - 双击 `frontend/index.html`
   - 或访问 `http://localhost:3000`

4. ✅ **测试基本功能**
   - 发送测试消息
   - 查看流式输出
   - 检查历史记录

5. ✅ **（可选）部署到服务器**
   - 参考 `DEPLOYMENT.md`
   - 运行 `deploy/deploy.sh`

## 💡 小贴士

1. **首次运行** 会自动创建数据库
2. **历史记录** 保存在 `backend/data/history.db`
3. **API密钥** 已配置，无需修改
4. **流式输出** 建议开启，体验更好
5. **思考过程** 可选开启，查看AI推理

## 🚀 开始使用！

**最简单的开始方式:**

```bash
# 1. 打开终端
cd D:\yuanshi

# 2. 启动
start.bat

# 3. 打开浏览器
# 双击 frontend/index.html
```

**就这么简单！** 🎉

---

**有问题？查看完整文档:**
- 快速开始: `QUICKSTART.md`
- 项目说明: `README.md`
- 部署指南: `DEPLOYMENT.md`

**祝测试愉快！** ✨

