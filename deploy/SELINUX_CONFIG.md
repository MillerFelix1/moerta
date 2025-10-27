# SELinux 配置指南

**适用于 Alibaba Cloud Linux 3 / RHEL / CentOS**

## 什么是 SELinux？

SELinux (Security-Enhanced Linux) 是 RHEL/CentOS 系统的安全增强机制。它可能会阻止 Nginx 连接到后端服务。

## 检查 SELinux 状态

```bash
# 查看 SELinux 状态
getenforce

# 可能的输出：
# Enforcing  - 强制模式（会阻止违规操作）
# Permissive - 宽容模式（仅记录日志）
# Disabled   - 已禁用
```

## 问题诊断

如果遇到 Nginx 502 错误，检查 SELinux：

```bash
# 查看 SELinux 日志
sudo tail -f /var/log/audit/audit.log | grep denied

# 临时禁用 SELinux 测试
sudo setenforce 0

# 重启 Nginx
sudo systemctl restart nginx

# 如果问题解决，说明是 SELinux 导致的
```

## 解决方案

### 方案1：配置 SELinux 策略（推荐）

允许 Nginx 连接到网络服务：

```bash
# 允许 httpd/nginx 连接到网络
sudo setsebool -P httpd_can_network_connect 1

# 允许 httpd/nginx 连接到数据库
sudo setsebool -P httpd_can_network_connect_db 1

# 重新启用 SELinux
sudo setenforce 1

# 验证设置
getsebool -a | grep httpd
```

### 方案2：为特定端口添加 SELinux 策略

```bash
# 允许 Nginx 连接到 8000 端口
sudo semanage port -a -t http_port_t -p tcp 8000

# 查看端口策略
sudo semanage port -l | grep http_port_t
```

### 方案3：临时禁用 SELinux

**⚠️ 仅用于测试，不推荐生产环境！**

```bash
# 临时禁用（重启后恢复）
sudo setenforce 0
```

### 方案4：永久禁用 SELinux

**⚠️ 不推荐！会降低系统安全性**

```bash
# 编辑配置文件
sudo nano /etc/selinux/config

# 修改为：
SELINUX=disabled

# 保存后重启系统
sudo reboot
```

## 常用命令

```bash
# 查看 SELinux 状态
sudo sestatus

# 查看布尔值
sudo getsebool -a

# 查看 SELinux 上下文
ls -Z /var/www/shangyu.icu

# 查看进程上下文
ps -eZ | grep nginx

# 恢复文件上下文
sudo restorecon -Rv /var/www/shangyu.icu
```

## 推荐配置

对于我们的应用，推荐使用**方案1**：

```bash
# 1. 允许 Nginx 网络连接
sudo setsebool -P httpd_can_network_connect 1

# 2. 允许自定义端口（如果需要）
sudo semanage port -a -t http_port_t -p tcp 8000 || true

# 3. 重启服务
sudo systemctl restart nginx
sudo systemctl restart data-expert

# 4. 验证
curl http://localhost:8000
```

## 故障排查

如果配置后仍有问题：

```bash
# 1. 查看 SELinux 日志
sudo ausearch -m avc -ts recent

# 2. 生成允许策略
sudo ausearch -m avc -ts recent | audit2allow

# 3. 应用策略（谨慎使用）
sudo ausearch -m avc -ts recent | audit2allow -M myapp
sudo semodule -i myapp.pp
```

## 参考资源

- Red Hat SELinux 文档: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/
- CentOS SELinux 指南: https://wiki.centos.org/HowTos/SELinux

---

**记住**: SELinux 是为了安全，不要轻易禁用！正确配置策略才是最佳实践。

