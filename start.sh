#!/bin/bash

echo "========================================="
echo "  数据解构专家 - 测试平台启动脚本"
echo "========================================="
echo ""

# 检查Python是否安装
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: 未找到Python3，请先安装Python 3.8或更高版本"
    exit 1
fi

echo "✅ Python版本: $(python3 --version)"
echo ""

# 进入后端目录
cd backend

# 检查依赖是否安装
if [ ! -d "venv" ]; then
    echo "📦 首次运行，正在安装依赖..."
    echo ""
    
    # 创建虚拟环境（可选）
    # python3 -m venv venv
    # source venv/bin/activate
    
    # 安装依赖
    pip3 install -r requirements.txt
    
    if [ $? -ne 0 ]; then
        echo "❌ 依赖安装失败，请检查网络连接"
        exit 1
    fi
    
    echo ""
    echo "✅ 依赖安装完成"
    echo ""
fi

# 检查.env文件
if [ ! -f ".env" ]; then
    echo "⚠️  警告: 未找到.env文件，将使用.env.example"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✅ 已创建.env文件，请编辑配置"
    else
        echo "❌ 错误: 未找到.env.example文件"
        exit 1
    fi
fi

# 创建数据目录
mkdir -p data

echo "🚀 正在启动后端服务..."
echo ""
echo "访问地址:"
echo "  - 后端API: http://localhost:8000"
echo "  - API文档: http://localhost:8000/docs"
echo "  - 前端页面: file://$(pwd)/../frontend/index.html"
echo ""
echo "按 Ctrl+C 停止服务"
echo ""
echo "========================================="
echo ""

# 启动服务
python3 server.py

