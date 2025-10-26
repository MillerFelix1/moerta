#!/bin/bash

# ===================================
# 智能更新脚本
# 只在必要时重建镜像
# ===================================

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo ""
echo "=========================================="
echo "  🔄 智能更新检测"
echo "=========================================="
echo ""

# 检查是否需要重建后端
REBUILD_BACKEND=false

# 检查后端相关文件的变化
if [ -f ".last_backend_hash" ]; then
    CURRENT_HASH=$(cat backend/server.py backend/requirements.txt Dockerfile 2>/dev/null | md5sum | cut -d' ' -f1)
    LAST_HASH=$(cat .last_backend_hash)
    
    if [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
        REBUILD_BACKEND=true
        print_warning "检测到后端代码变化，需要重建镜像"
    else
        print_success "后端代码未变化，无需重建镜像"
    fi
else
    REBUILD_BACKEND=true
    print_info "首次部署或缓存已清除，需要构建镜像"
fi

# 检查前端文件
FRONTEND_CHANGED=false
if [ -f "frontend/index-optimized.html" ]; then
    if ! cmp -s frontend/index-optimized.html frontend/index.html 2>/dev/null; then
        FRONTEND_CHANGED=true
        print_info "检测到前端文件更新"
    fi
fi

echo ""
echo "=========================================="
echo "  📋 更新计划"
echo "=========================================="
echo ""

if [ "$FRONTEND_CHANGED" = true ]; then
    echo "✅ 前端: 更新文件（无需重建）"
else
    echo "⏭️  前端: 无变化"
fi

if [ "$REBUILD_BACKEND" = true ]; then
    echo "🔨 后端: 重建 Docker 镜像"
else
    echo "⏭️  后端: 无变化"
fi

echo ""

# 前端更新
if [ "$FRONTEND_CHANGED" = true ]; then
    print_info "更新前端文件..."
    cp frontend/index-optimized.html frontend/index.html
    if [ -f "PWA-manifest.json" ]; then
        cp PWA-manifest.json frontend/manifest.json
    fi
    print_success "前端文件已更新"
fi

# 后端更新
if [ "$REBUILD_BACKEND" = true ]; then
    print_info "重建后端 Docker 镜像（这需要几分钟）..."
    
    # 构建镜像
    if docker compose build backend; then
        print_success "后端镜像构建完成"
        
        # 保存当前哈希
        cat backend/server.py backend/requirements.txt Dockerfile 2>/dev/null | md5sum | cut -d' ' -f1 > .last_backend_hash
    else
        echo "❌ 镜像构建失败"
        exit 1
    fi
fi

# 重启服务
echo ""
print_info "重启服务..."

if [ "$REBUILD_BACKEND" = true ]; then
    # 后端改变，重启所有
    docker compose up -d
    print_success "所有服务已重启"
elif [ "$FRONTEND_CHANGED" = true ]; then
    # 只前端改变，只重启 Nginx
    docker compose restart nginx
    print_success "Nginx 已重启"
else
    # 都没变化
    print_info "无需重启服务"
fi

# 等待服务启动
if [ "$REBUILD_BACKEND" = true ]; then
    print_info "等待后端健康检查（30秒）..."
    sleep 30
elif [ "$FRONTEND_CHANGED" = true ]; then
    print_info "等待 Nginx 重启..."
    sleep 3
fi

# 验证
echo ""
echo "=========================================="
echo "  ✅ 更新完成"
echo "=========================================="
echo ""

# 显示状态
docker compose ps

echo ""

# 测试
print_info "快速测试..."
if curl -s http://localhost/ > /dev/null 2>&1; then
    print_success "前端访问正常"
else
    echo "⚠️  前端可能需要检查"
fi

if curl -s http://localhost:8000/ > /dev/null 2>&1; then
    print_success "后端访问正常"
else
    echo "⚠️  后端可能需要检查"
fi

echo ""
print_success "更新完成！访问: https://shangyu.icu"
echo ""

