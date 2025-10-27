# ✅ 部署检查清单

## 📦 上传前检查（本地）

- [ ] 所有文件已更新到最新版本
- [ ] `frontend/index-optimized.html` 存在且完整 (1400+ 行)
- [ ] `PWA-manifest.json` 存在
- [ ] `backend/server.py` 包含最新优化
- [ ] `docker-compose.yml` 使用 v2.0 配置
- [ ] `Dockerfile` 包含 curl 和健康检查
- [ ] `deploy/nginx-docker.conf` 使用优化配置
- [ ] `deploy-production.sh` 可执行
- [ ] `check-system.sh` 可执行

---

## 📤 上传到服务器

### 方法 1: Git（推荐）

```bash
# 本地提交
git add .
git commit -m "v2.0: 完整优化版本"
git push

# 服务器拉取
ssh admin@8.137.51.166
cd /var/www/shangyu.icu/yuanshi
git pull
```

### 方法 2: SCP/SFTP

```bash
# 压缩项目
tar -czf yuanshi-v2.tar.gz yuanshi/

# 上传
scp yuanshi-v2.tar.gz admin@8.137.51.166:/var/www/shangyu.icu/

# 服务器解压
ssh admin@8.137.51.166
cd /var/www/shangyu.icu
tar -xzf yuanshi-v2.tar.gz
```

---

## 🚀 服务器部署检查

### 1️⃣ 环境检查

```bash
# SSH 登录
ssh admin@8.137.51.166

# 检查 Docker
docker --version          # 应该 ≥ 20.10
docker compose version    # 应该 ≥ 2.0

# 进入项目目录
cd /var/www/shangyu.icu/yuanshi

# 检查文件完整性
ls -lh frontend/index-optimized.html    # 应该 100KB+
ls -lh backend/server.py                # 应该 20KB+
ls -lh docker-compose.yml
ls -lh Dockerfile
```

- [ ] Docker 版本正确
- [ ] Docker Compose 版本正确
- [ ] 所有关键文件存在
- [ ] 文件大小正常

---

### 2️⃣ 赋予执行权限

```bash
chmod +x deploy-production.sh
chmod +x check-system.sh
```

- [ ] 脚本可执行

---

### 3️⃣ 执行部署

```bash
bash deploy-production.sh
```

**观察输出，确认:**

- [ ] ✅ 环境检查通过
- [ ] ✅ 前端文件准备完成
- [ ] ✅ 环境变量配置完成
- [ ] ✅ 数据目录创建完成
- [ ] ✅ 旧容器清理完成
- [ ] ✅ Docker 镜像构建成功
- [ ] ✅ 服务启动成功
- [ ] ✅ 容器状态为 "Up"
- [ ] ✅ 后端 API 测试通过
- [ ] ✅ 前端访问测试通过
- [ ] ✅ API 代理测试通过

**预期部署时间:** 3-5 分钟

---

### 4️⃣ 容器状态验证

```bash
docker compose ps
```

**期望输出:**

```
NAME                            STATUS
memory-reconstruction-backend   Up (healthy)
memory-reconstruction-nginx     Up
```

- [ ] 后端容器运行中
- [ ] 后端健康检查通过
- [ ] Nginx 容器运行中

---

### 5️⃣ 网络测试

```bash
# 本地测试
curl http://localhost/
curl http://localhost:8000/
curl http://localhost/api/sessions

# 公网测试（从服务器本机）
curl http://8.137.51.166/
```

- [ ] 本地前端访问正常
- [ ] 本地后端访问正常
- [ ] 本地 API 代理正常
- [ ] 公网 IP 访问正常

---

### 6️⃣ 防火墙检查

```bash
# 查看防火墙规则
sudo firewall-cmd --list-all

# 确认端口开放
sudo firewall-cmd --list-ports | grep -E '80|443'
```

- [ ] 端口 80 已开放
- [ ] 端口 443 已开放（HTTPS）

---

### 7️⃣ 阿里云安全组检查

**登录阿里云控制台:**

1. 进入 **ECS 控制台**
2. 选择实例 **8.137.51.166**
3. 点击 **安全组**
4. 查看 **入方向规则**

**确认规则存在:**

- [ ] 端口 `80/80`, TCP, 授权对象 `0.0.0.0/0`
- [ ] 端口 `443/443`, TCP, 授权对象 `0.0.0.0/0`

---

### 8️⃣ 日志检查

```bash
# 查看最近日志
docker compose logs --tail 50

# 检查是否有错误
docker compose logs | grep -i error
docker compose logs | grep -i fail
```

- [ ] 无严重错误
- [ ] 无重复重启
- [ ] 后端正常输出启动信息

---

### 9️⃣ 健康检查脚本

```bash
bash check-system.sh
```

**期望输出:**

- [ ] ✅ 后端容器运行中
- [ ] ✅ Nginx 容器运行中
- [ ] ✅ 后端 API 正常 [200]
- [ ] ✅ 前端访问正常 [200]
- [ ] ✅ API 代理正常 [200]
- [ ] ✅ frontend/index.html 完整
- [ ] ✅ backend/.env 存在
- [ ] ✅ 端口 80 已监听
- [ ] ✅ 端口 8000 已监听

---

## 🌐 浏览器测试

### 在你的电脑/手机浏览器访问

**URL:** https://shangyu.icu 或 http://8.137.51.166

### 视觉检查

- [ ] 页面正常加载（不是 404/502）
- [ ] 背景是白色
- [ ] 左侧显示 "🧠 Memory Reconstruction"
- [ ] 左侧显示 "新建对话" 按钮
- [ ] 中间显示 3 个快速示例卡片
- [ ] 底部显示输入框和发送按钮
- [ ] 移动端：右下角有圆形菜单按钮

### 功能测试

- [ ] 点击 "新建对话" 创建会话
- [ ] 发送一条消息，能收到 AI 回复
- [ ] 回复以流式方式显示（逐字输出）
- [ ] 左侧会话列表显示新会话
- [ ] 会话标题自动生成（不是 "新对话"）
- [ ] 可以切换不同会话
- [ ] 可以删除会话
- [ ] 可以重命名会话
- [ ] 代码块有语法高亮
- [ ] 代码块有复制按钮
- [ ] 页面滚动流畅
- [ ] 移动端适配良好

---

## 📱 移动端测试

### 手机浏览器打开

- [ ] 页面完整显示，无横向滚动
- [ ] 右下角显示圆形菜单按钮（≡）
- [ ] 点击菜单可展开侧边栏
- [ ] 输入框字体大小合适（不会自动缩放）
- [ ] 可以正常发送消息
- [ ] 虚拟键盘不会遮挡输入框
- [ ] 流式输出流畅

### PWA 安装测试（可选）

- [ ] 浏览器提示 "添加到主屏幕"
- [ ] 安装后可以独立打开
- [ ] 图标和名称正确

---

## 🎯 性能测试

### 响应速度

```bash
# 测试后端响应时间
time curl -s http://localhost/api/sessions > /dev/null

# 测试前端加载时间
time curl -s http://localhost/ > /dev/null
```

- [ ] 后端响应 < 1秒
- [ ] 前端加载 < 2秒

### 并发测试（可选）

```bash
# 安装 ab（Apache Bench）
sudo yum install httpd-tools

# 100 个请求，10 个并发
ab -n 100 -c 10 http://localhost/
```

- [ ] 无错误请求
- [ ] 平均响应时间 < 500ms

---

## 📊 监控设置（可选）

### 设置定时健康检查

```bash
# 创建 cron 任务
sudo crontab -e

# 添加以下行（每 5 分钟检查一次）
*/5 * * * * cd /var/www/shangyu.icu/yuanshi && bash check-system.sh > /tmp/health-check.log 2>&1
```

- [ ] Cron 任务已设置

---

## 🎉 部署完成确认

### 最终检查

- [ ] 所有上述检查项都已 ✅
- [ ] 网站可从外网正常访问
- [ ] 功能完整可用
- [ ] 无报错或警告
- [ ] 日志输出正常

### 通知相关人员

- [ ] 更新 DNS（如有需要）
- [ ] 通知团队部署完成
- [ ] 更新文档版本号

---

## 📝 记录部署信息

**部署日期:** ____________________

**部署版本:** v2.0

**部署人员:** ____________________

**服务器 IP:** 8.137.51.166

**域名:** shangyu.icu

**容器状态:**
- Backend: ☐ Running ☐ Issue
- Nginx: ☐ Running ☐ Issue

**测试结果:**
- 功能测试: ☐ Pass ☐ Fail
- 性能测试: ☐ Pass ☐ Fail
- 移动端测试: ☐ Pass ☐ Fail

**备注:**

________________________________________________

________________________________________________

________________________________________________

---

## 🆘 遇到问题？

1. ✅ 检查 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. 🔍 运行 `bash check-system.sh`
3. 📝 查看 `docker compose logs -f`
4. 🔄 尝试 `docker compose restart`
5. 🔧 完全重建 `docker compose down && docker compose up -d --build`

---

<div align="center">

**Memory Reconstruction Platform v2.0**

**🎯 目标：零错误、极致体验**

[⬆ 回到顶部](#-部署检查清单)

</div>

