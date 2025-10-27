#!/bin/bash

# ===================================
# Memory Reconstruction Platform
# 生产环境完整部署脚本 v2.0
# ===================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
print_step() { echo -e "${PURPLE}▶️  $1${NC}"; }

# 显示标题
echo ""
echo "=========================================="
echo "  🧠 Memory Reconstruction Platform"
echo "  生产环境部署脚本 v2.0"
echo "=========================================="
echo ""

# ===== 步骤 1: 环境检查 =====
print_step "步骤 1/8: 环境检查"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker 未安装！请先安装 Docker"
    exit 1
fi
print_info "Docker 版本: $(docker --version | cut -d' ' -f3)"

# 检查 Docker Compose
if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    print_error "Docker Compose 未安装或版本过低！"
    exit 1
fi
print_info "Docker Compose 版本: $(docker compose version --short)"

# 检查关键文件
print_info "检查项目文件..."
required_files=(
    "docker-compose.yml"
    "Dockerfile"
    "backend/requirements.txt"
    "backend/server.py"
    "frontend/index-optimized.html"
    "deploy/nginx-docker.conf"
    "PWA-manifest.json"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -ne 0 ]; then
    print_error "缺少必要文件:"
    for file in "${missing_files[@]}"; do
        echo "  - $file"
    done
    exit 1
fi

print_success "环境检查完成"
echo ""

# ===== 步骤 2: 准备前端文件 =====
print_step "步骤 2/8: 准备前端文件"

# 使用优化版本
print_info "复制优化版本的前端文件..."
cp -f frontend/index-optimized.html frontend/index.html
print_success "前端主文件已更新 ($(wc -l < frontend/index.html) 行)"

# 复制 PWA manifest
if [ -f "PWA-manifest.json" ]; then
    cp -f PWA-manifest.json frontend/manifest.json
    print_success "PWA manifest 已添加"
fi

# 检查文件大小
html_size=$(stat -c%s frontend/index.html 2>/dev/null || stat -f%z frontend/index.html 2>/dev/null)
if [ "$html_size" -lt 50000 ]; then
    print_warning "警告: index.html 文件可能不完整 (${html_size} bytes)"
fi

print_success "前端文件准备完成"
echo ""

# ===== 步骤 3: 配置环境变量 =====
print_step "步骤 3/8: 配置环境变量"

# 创建 .env 文件
if [ ! -f "backend/.env" ]; then
    print_info "创建环境配置文件..."
    cat > backend/.env << 'EOF'
# 阿里百炼 API 配置
DASHSCOPE_API_KEY=sk-31d4c4895a6d4a959fa9f4ff029515ac
DASHSCOPE_APP_ID=6596ab6827f445f08abc4194be485bc1

# 服务器配置
HOST=0.0.0.0
PORT=8000

# 数据库配置
DATABASE_PATH=./data/sessions.db
EOF
    print_success "环境配置文件已创建"
else
    print_info "环境配置文件已存在"
fi

# 验证 API Key
if grep -q "sk-31d4c4895a6d4a959fa9f4ff029515ac" backend/.env; then
    print_success "API 配置验证通过"
else
    print_warning "请检查 backend/.env 中的 API Key 配置"
fi

echo ""

# ===== 步骤 4: 创建必要目录 =====
print_step "步骤 4/8: 创建数据目录"

mkdir -p backend/data
mkdir -p ssl
mkdir -p logs

print_success "目录结构已创建"
echo ""

# ===== 步骤 5: 清理旧容器 =====
print_step "步骤 5/8: 清理旧容器"

print_info "停止并删除旧容器..."
docker compose down -v 2>/dev/null || true

# 删除旧镜像（可选）
read -p "$(echo -e ${YELLOW}是否删除旧镜像以确保完全重建？[y/N]: ${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "删除旧镜像..."
    docker rmi memory-reconstruction-backend:latest 2>/dev/null || true
    print_success "旧镜像已删除"
fi

print_success "清理完成"
echo ""

# ===== 步骤 6: 构建镜像 =====
print_step "步骤 6/8: 构建 Docker 镜像"

# 询问是否使用缓存
echo ""
print_info "构建选项："
echo "  1) 使用缓存构建（快速，推荐）"
echo "  2) 完全重建，不使用缓存（慢，但确保最新）"
echo ""
read -p "$(echo -e ${CYAN}选择 [1]: ${NC})" -n 1 -r
echo ""
BUILD_OPTION=${REPLY:-1}

if [ "$BUILD_OPTION" = "2" ]; then
    print_info "开始完全重建（这需要 3-5 分钟）..."
    BUILD_FLAGS="--no-cache"
else
    print_info "使用缓存构建（这需要 30-60 秒）..."
    BUILD_FLAGS=""
fi

if docker compose build $BUILD_FLAGS 2>&1 | tee /tmp/docker-build.log; then
    print_success "镜像构建成功"
else
    print_error "镜像构建失败！查看日志: /tmp/docker-build.log"
    exit 1
fi

echo ""

# ===== 步骤 7: 启动服务 =====
print_step "步骤 7/8: 启动服务"

print_info "启动容器..."
docker compose up -d

print_info "等待服务启动（40秒）..."
for i in {1..40}; do
    echo -ne "\r  进度: [$i/40] $(printf '█%.0s' $(seq 1 $((i*50/40))))$(printf '░%.0s' $(seq 1 $((50-i*50/40))))"
    sleep 1
done
echo ""

print_success "服务已启动"
echo ""

# ===== 步骤 8: 验证部署 =====
print_step "步骤 8/8: 验证部署"

echo ""
echo "=========================================="
echo "  📊 容器状态"
echo "=========================================="
docker compose ps
echo ""

# 检查容器是否运行
backend_status=$(docker inspect -f '{{.State.Status}}' memory-reconstruction-backend 2>/dev/null || echo "not found")
nginx_status=$(docker inspect -f '{{.State.Status}}' memory-reconstruction-nginx 2>/dev/null || echo "not found")

if [ "$backend_status" != "running" ]; then
    print_error "后端容器未运行！状态: $backend_status"
    echo ""
    echo "后端日志:"
    docker compose logs --tail 50 backend
    exit 1
fi

if [ "$nginx_status" != "running" ]; then
    print_error "Nginx 容器未运行！状态: $nginx_status"
    echo ""
    echo "Nginx 日志:"
    docker compose logs --tail 50 nginx
    exit 1
fi

print_success "所有容器运行正常"
echo ""

# 测试后端 API
echo "=========================================="
echo "  🧪 API 测试"
echo "=========================================="

print_info "测试后端健康检查..."
if backend_response=$(curl -s http://localhost:8000/ 2>&1); then
    echo "$backend_response" | grep -q "running" && print_success "后端 API 响应正常" || print_warning "后端响应异常"
    echo "  响应: $backend_response"
else
    print_error "无法连接到后端"
fi

echo ""

print_info "测试前端访问..."
if frontend_response=$(curl -I http://localhost/ 2>&1 | head -1); then
    echo "$frontend_response" | grep -q "200" && print_success "前端访问正常" || print_warning "前端响应异常"
    echo "  响应: $frontend_response"
else
    print_error "无法访问前端"
fi

echo ""

print_info "测试 API 代理..."
if api_response=$(curl -s http://localhost/api/sessions 2>&1); then
    echo "$api_response" | grep -q "\[" && print_success "API 代理正常" || print_warning "API 代理响应异常"
    echo "  响应: $(echo $api_response | head -c 100)..."
else
    print_error "API 代理测试失败"
fi

echo ""

# 显示最新日志
echo "=========================================="
echo "  📝 最新日志（最后 10 行）"
echo "=========================================="
echo ""
echo "--- 后端日志 ---"
docker compose logs --tail 10 backend
echo ""
echo "--- Nginx 日志 ---"
docker compose logs --tail 10 nginx
echo ""

# ===== 部署完成 =====
echo "=========================================="
echo "  ✅ 部署完成！"
echo "=========================================="
echo ""
print_success "Memory Reconstruction Platform 已成功部署！"
echo ""
echo "📍 访问信息:"
echo "  🌐 网站地址: https://shangyu.icu"
echo "  🌐 IP 访问:   http://8.137.51.166"
echo "  🔧 本地测试:  http://localhost"
echo ""
echo "🛠️  管理命令:"
echo "  查看日志: docker compose logs -f"
echo "  重启服务: docker compose restart"
echo "  停止服务: docker compose down"
echo "  查看状态: docker compose ps"
echo ""
echo "📊 系统信息:"
echo "  后端状态: $backend_status"
echo "  Nginx状态: $nginx_status"
echo "  数据目录: $(pwd)/backend/data"
echo ""
print_info "建议: 使用 'docker compose logs -f' 监控实时日志"
echo ""

