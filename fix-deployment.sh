#!/bin/bash

echo "🔧 修复部署问题..."

# 1. 检查文件是否存在
if [ ! -f "frontend/index-optimized.html" ]; then
    echo "❌ 错误: frontend/index-optimized.html 不存在"
    exit 1
fi

# 2. 复制优化版本
echo "📝 复制优化版本..."
cp frontend/index-optimized.html frontend/index.html

# 3. 添加 PWA manifest
if [ -f "PWA-manifest.json" ]; then
    cp PWA-manifest.json frontend/manifest.json
    echo "✅ PWA manifest 已添加"
fi

# 4. 检查文件
echo "📋 检查文件..."
ls -lh frontend/index.html frontend/index-optimized.html

# 5. 重启服务（不需要重新构建，因为是卷挂载）
echo "🔄 重启服务..."
docker compose restart nginx

# 6. 等待启动
sleep 3

# 7. 测试
echo "🧪 测试前端..."
curl -I http://localhost/ 2>/dev/null | head -5

echo ""
echo "✅ 修复完成！"
echo "访问: https://shangyu.icu"

