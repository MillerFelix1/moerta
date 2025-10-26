#!/bin/bash

# ===================================
# Memory Reconstruction Platform
# 系统健康检查脚本
# ===================================

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
echo "  🔍 系统健康检查"
echo "=========================================="
echo ""

# 1. 检查容器状态
echo "1️⃣  容器状态检查"
echo "---"
docker compose ps
echo ""

backend_status=$(docker inspect -f '{{.State.Status}}' memory-reconstruction-backend 2>/dev/null || echo "not_found")
nginx_status=$(docker inspect -f '{{.State.Status}}' memory-reconstruction-nginx 2>/dev/null || echo "not_found")

if [ "$backend_status" = "running" ]; then
    print_success "后端容器运行中"
else
    print_error "后端容器状态异常: $backend_status"
fi

if [ "$nginx_status" = "running" ]; then
    print_success "Nginx 容器运行中"
else
    print_error "Nginx 容器状态异常: $nginx_status"
fi

echo ""

# 2. 网络连接测试
echo "2️⃣  网络连接测试"
echo "---"

# 测试后端
print_info "测试后端 API (http://localhost:8000/)..."
if response=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost:8000/ 2>&1); then
    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d: -f2)
    body=$(echo "$response" | grep -v "HTTP_CODE")
    
    if [ "$http_code" = "200" ]; then
        print_success "后端 API 正常 [200]"
        echo "  响应: $body"
    else
        print_warning "后端响应码: $http_code"
        echo "  响应: $body"
    fi
else
    print_error "无法连接到后端"
fi

echo ""

# 测试前端
print_info "测试前端 (http://localhost/)..."
if response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -I http://localhost/ 2>&1); then
    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d: -f2)
    
    if [ "$http_code" = "200" ]; then
        print_success "前端访问正常 [200]"
    else
        print_warning "前端响应码: $http_code"
    fi
else
    print_error "无法访问前端"
fi

echo ""

# 测试 API 代理
print_info "测试 API 代理 (http://localhost/api/sessions)..."
if response=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost/api/sessions 2>&1); then
    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d: -f2)
    body=$(echo "$response" | grep -v "HTTP_CODE")
    
    if [ "$http_code" = "200" ]; then
        print_success "API 代理正常 [200]"
        echo "  响应: $(echo $body | head -c 80)..."
    else
        print_warning "API 代理响应码: $http_code"
        echo "  响应: $body"
    fi
else
    print_error "API 代理测试失败"
fi

echo ""

# 3. 文件检查
echo "3️⃣  关键文件检查"
echo "---"

# 检查前端文件
if [ -f "frontend/index.html" ]; then
    file_size=$(stat -c%s frontend/index.html 2>/dev/null || stat -f%z frontend/index.html 2>/dev/null)
    file_lines=$(wc -l < frontend/index.html)
    
    if [ "$file_size" -gt 100000 ]; then
        print_success "frontend/index.html 完整 (${file_size} bytes, ${file_lines} 行)"
    else
        print_warning "frontend/index.html 可能不完整 (${file_size} bytes)"
    fi
else
    print_error "frontend/index.html 不存在"
fi

# 检查 .env 文件
if [ -f "backend/.env" ]; then
    print_success "backend/.env 存在"
    if grep -q "DASHSCOPE_API_KEY" backend/.env; then
        print_info "  ✓ API Key 已配置"
    else
        print_warning "  ✗ API Key 未配置"
    fi
    if grep -q "DASHSCOPE_APP_ID" backend/.env; then
        print_info "  ✓ App ID 已配置"
    else
        print_warning "  ✗ App ID 未配置"
    fi
else
    print_error "backend/.env 不存在"
fi

echo ""

# 4. 端口检查
echo "4️⃣  端口占用检查"
echo "---"

if command -v ss &> /dev/null; then
    port_80=$(ss -tlnp 2>/dev/null | grep ":80 " | wc -l)
    port_8000=$(ss -tlnp 2>/dev/null | grep ":8000 " | wc -l)
    
    [ "$port_80" -gt 0 ] && print_success "端口 80 已监听" || print_error "端口 80 未监听"
    [ "$port_8000" -gt 0 ] && print_success "端口 8000 已监听" || print_error "端口 8000 未监听"
elif command -v lsof &> /dev/null; then
    port_80=$(lsof -i :80 2>/dev/null | wc -l)
    port_8000=$(lsof -i :8000 2>/dev/null | wc -l)
    
    [ "$port_80" -gt 0 ] && print_success "端口 80 已监听" || print_error "端口 80 未监听"
    [ "$port_8000" -gt 0 ] && print_success "端口 8000 已监听" || print_error "端口 8000 未监听"
else
    print_warning "无法检查端口（ss/lsof 未安装）"
fi

echo ""

# 5. 日志检查（最后 5 行）
echo "5️⃣  最新日志"
echo "---"

echo "后端日志（最后 5 行）:"
docker compose logs --tail 5 backend 2>/dev/null | sed 's/^/  /'

echo ""
echo "Nginx 日志（最后 5 行）:"
docker compose logs --tail 5 nginx 2>/dev/null | sed 's/^/  /'

echo ""

# 6. 磁盘空间
echo "6️⃣  磁盘空间"
echo "---"

if [ -d "backend/data" ]; then
    data_size=$(du -sh backend/data 2>/dev/null | cut -f1)
    print_info "数据目录大小: $data_size"
fi

echo ""

# 总结
echo "=========================================="
echo "  📊 检查完成"
echo "=========================================="
echo ""

if [ "$backend_status" = "running" ] && [ "$nginx_status" = "running" ]; then
    print_success "系统运行正常！✨"
    echo ""
    echo "📍 访问地址:"
    echo "  🌐 https://shangyu.icu"
    echo "  🔗 http://8.137.51.166"
else
    print_error "系统存在问题，请查看上方详情"
    echo ""
    echo "🔧 故障排除:"
    echo "  1. 查看完整日志: docker compose logs -f"
    echo "  2. 重启服务: docker compose restart"
    echo "  3. 重新部署: bash deploy-production.sh"
fi

echo ""

