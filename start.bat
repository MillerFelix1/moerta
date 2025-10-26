@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo =========================================
echo   数据解构专家 - 测试平台启动脚本
echo =========================================
echo.

REM 检查Python是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误: 未找到Python，请先安装Python 3.8或更高版本
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('python --version') do set PYTHON_VERSION=%%i
echo ✅ Python版本: %PYTHON_VERSION%
echo.

REM 进入后端目录
cd backend

REM 检查依赖是否安装
if not exist "venv\" (
    echo 📦 首次运行，正在安装依赖...
    echo.
    
    REM 创建虚拟环境（可选）
    REM python -m venv venv
    REM call venv\Scripts\activate.bat
    
    REM 安装依赖
    python -m pip install -r requirements.txt
    
    if errorlevel 1 (
        echo ❌ 依赖安装失败，请检查网络连接
        pause
        exit /b 1
    )
    
    echo.
    echo ✅ 依赖安装完成
    echo.
)

REM 检查.env文件
if not exist ".env" (
    echo ⚠️  警告: 未找到.env文件，将使用.env.example
    if exist ".env.example" (
        copy .env.example .env >nul
        echo ✅ 已创建.env文件，请编辑配置
    ) else (
        echo ❌ 错误: 未找到.env.example文件
        pause
        exit /b 1
    )
)

REM 创建数据目录
if not exist "data\" mkdir data

echo 🚀 正在启动后端服务...
echo.
echo 访问地址:
echo   - 后端API: http://localhost:8000
echo   - API文档: http://localhost:8000/docs
echo   - 前端页面: file:///%CD%\..\frontend\index.html
echo.
echo 按 Ctrl+C 停止服务
echo.
echo =========================================
echo.

REM 启动服务
python server.py

pause

