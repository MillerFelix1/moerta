#!/bin/bash

# Memory Reconstruction - 快速更新脚本
# 用于一键部署优化版本

set -e

echo "========================================="
echo "  Memory Reconstruction - 快速更新"
echo "========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否在项目目录
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 错误: 请在项目根目录执行此脚本"
    exit 1
fi

echo "${BLUE}📦 步骤 1/5: 备份当前版本${NC}"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p backups
cp frontend/index.html "backups/index-backup-${BACKUP_DATE}.html" 2>/dev/null || true
echo "${GREEN}✅ 备份完成${NC}"
echo ""

echo "${BLUE}📝 步骤 2/5: 更新文件${NC}"
# 使用优化版本
if [ -f "frontend/index-optimized.html" ]; then
    cp frontend/index-optimized.html frontend/index.html
    echo "${GREEN}✅ 前端已更新${NC}"
else
    echo "${YELLOW}⚠️  未找到 index-optimized.html，跳过前端更新${NC}"
fi

# 添加 PWA manifest
if [ -f "PWA-manifest.json" ]; then
    cp PWA-manifest.json frontend/manifest.json
    echo "${GREEN}✅ PWA manifest 已添加${NC}"
fi
echo ""

echo "${BLUE}🛑 步骤 3/5: 停止现有服务${NC}"
docker compose down
echo "${GREEN}✅ 服务已停止${NC}"
echo ""

echo "${BLUE}🔨 步骤 4/5: 重新构建镜像${NC}"
echo "这可能需要几分钟..."
docker compose build --no-cache
echo "${GREEN}✅ 构建完成${NC}"
echo ""

echo "${BLUE}🚀 步骤 5/5: 启动服务${NC}"
docker compose up -d
echo "${GREEN}✅ 服务已启动${NC}"
echo ""

# 等待服务就绪
echo "${BLUE}⏳ 等待服务启动...${NC}"
sleep 5

# 检查服务状态
echo ""
echo "========================================="
echo "  服务状态检查"
echo "========================================="
docker compose ps
echo ""

# 测试后端
echo "${BLUE}🧪 测试后端连接...${NC}"
if curl -s http://localhost:8000/ > /dev/null; then
    echo "${GREEN}✅ 后端服务正常${NC}"
else
    echo "${YELLOW}⚠️  后端服务未响应，请检查日志${NC}"
fi
echo ""

# 测试前端
echo "${BLUE}🧪 测试前端连接...${NC}"
if curl -s http://localhost/ > /dev/null; then
    echo "${GREEN}✅ 前端服务正常${NC}"
else
    echo "${YELLOW}⚠️  前端服务未响应，请检查日志${NC}"
fi
echo ""

echo "========================================="
echo "  🎉 更新完成！"
echo "========================================="
echo ""
echo "访问地址: ${GREEN}https://shangyu.icu${NC}"
echo ""
echo "新功能："
echo "  ✨ 智能标题自动生成"
echo "  📥 会话导出（Markdown/JSON/TXT）"
echo "  🎨 代码语法高亮"
echo "  📋 一键复制代码"
echo "  ⌨️  键盘快捷键（Cmd+K, Esc）"
echo "  📱 完美的移动端体验"
echo ""
echo "查看日志: ${BLUE}docker compose logs -f${NC}"
echo "回滚版本: ${BLUE}cp backups/index-backup-${BACKUP_DATE}.html frontend/index.html${NC}"
echo ""
echo "========================================="

