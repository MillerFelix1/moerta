@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ===================================
:: Memory Reconstruction Platform
:: 本地开发启动脚本
:: ===================================

echo.
echo ==========================================
echo   🧠 Memory Reconstruction Platform
echo   本地开发环境启动
echo ==========================================
echo.

:: 检查 Docker 是否运行
echo [1/6] 检查 Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker 未安装或未运行！
    echo.
    echo 请先安装并启动 Docker Desktop for Windows
    echo 下载地址: https://www.docker.com/products/docker-desktop/
    pause
    exit /b 1
)
echo ✅ Docker 已运行

:: 准备前端文件
echo.
echo [2/6] 准备前端文件...
copy /Y frontend\index-optimized.html frontend\index.html >nul
if exist PWA-manifest.json (
    copy /Y PWA-manifest.json frontend\manifest.json >nul
)
echo ✅ 前端文件已准备

:: 创建环境配置
echo.
echo [3/6] 配置环境变量...
if not exist backend\.env (
    (
        echo DASHSCOPE_API_KEY=sk-31d4c4895a6d4a959fa9f4ff029515ac
        echo DASHSCOPE_APP_ID=6596ab6827f445f08abc4194be485bc1
        echo HOST=0.0.0.0
        echo PORT=8000
        echo DATABASE_PATH=./data/sessions.db
    ) > backend\.env
    echo ✅ 环境配置已创建
) else (
    echo ✅ 环境配置已存在
)

:: 创建目录
echo.
echo [4/6] 创建必要目录...
if not exist backend\data mkdir backend\data
if not exist ssl mkdir ssl
echo ✅ 目录已创建

:: 启动服务
echo.
echo [5/6] 启动 Docker 服务...
echo 💡 首次启动需要构建镜像，可能需要几分钟...
echo.
docker compose up -d --build

if errorlevel 1 (
    echo.
    echo ❌ 启动失败！请查看错误信息
    pause
    exit /b 1
)

:: 等待服务启动
echo.
echo [6/6] 等待服务启动（30秒）...
timeout /t 30 /nobreak >nul

:: 显示状态
echo.
echo ==========================================
echo   📊 服务状态
echo ==========================================
docker compose ps

:: 测试访问
echo.
echo ==========================================
echo   🧪 快速测试
echo ==========================================
echo.
echo 测试后端 API...
curl -s http://localhost:8000/ | findstr "status" >nul
if errorlevel 1 (
    echo ⚠️  后端可能还在启动中
) else (
    echo ✅ 后端 API 正常
)

echo.
echo 测试前端...
curl -I http://localhost/ 2>nul | findstr "200" >nul
if errorlevel 1 (
    echo ⚠️  前端可能还在启动中
) else (
    echo ✅ 前端访问正常
)

:: 完成
echo.
echo ==========================================
echo   ✅ 启动完成！
echo ==========================================
echo.
echo 📍 访问地址:
echo   🌐 前端: http://localhost
echo   🔧 后端: http://localhost:8000
echo.
echo 🛠️  常用命令:
echo   查看日志: docker compose logs -f
echo   停止服务: docker compose down
echo   重启服务: docker compose restart
echo   查看状态: docker compose ps
echo.
echo 💡 现在可以打开浏览器访问 http://localhost 进行测试！
echo.

:: 询问是否打开浏览器
set /p "OPEN=是否打开浏览器？(Y/N): "
if /i "%OPEN%"=="Y" (
    start http://localhost
)

echo.
pause

