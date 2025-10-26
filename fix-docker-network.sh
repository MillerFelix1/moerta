#!/bin/bash

# ===================================
# Docker 网络问题修复脚本
# 配置国内镜像加速器
# ===================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }

echo ""
echo "=========================================="
echo "  🔧 Docker 镜像加速配置"
echo "=========================================="
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    print_error "请使用 sudo 运行此脚本"
    echo "用法: sudo bash fix-docker-network.sh"
    exit 1
fi

# 1. 备份现有配置
print_info "备份现有 Docker 配置..."
if [ -f /etc/docker/daemon.json ]; then
    cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
    print_success "已备份到: /etc/docker/daemon.json.backup.*"
else
    print_info "没有现有配置文件"
fi

# 2. 创建配置目录
mkdir -p /etc/docker

# 3. 写入新配置
print_info "配置镜像加速器..."

cat > /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://dockerproxy.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

print_success "配置文件已创建"

# 4. 重启 Docker
print_info "重启 Docker 服务..."
systemctl daemon-reload
systemctl restart docker

# 等待 Docker 启动
sleep 5

# 5. 验证配置
print_info "验证配置..."
echo ""
docker info | grep -A 10 "Registry Mirrors" || print_warning "无法显示镜像源信息"

echo ""

# 6. 测试网络
print_info "测试镜像拉取..."
if timeout 30 docker pull hello-world > /dev/null 2>&1; then
    print_success "网络测试通过！可以拉取镜像"
    docker rmi hello-world > /dev/null 2>&1
else
    print_warning "网络仍然较慢，但已配置加速器"
fi

echo ""
echo "=========================================="
echo "  ✅ 配置完成"
echo "=========================================="
echo ""

print_info "已配置的镜像源："
echo "  1. 中国科技大学镜像"
echo "  2. 网易镜像"
echo "  3. 百度云镜像"
echo "  4. DockerProxy"
echo ""

print_success "现在可以重新运行部署脚本了！"
echo ""
echo "运行: cd /var/www/shangyu.icu/yuanshi && bash deploy-production.sh"
echo ""

