@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ===================================
:: 本地环境问题修复脚本
:: ===================================

echo.
echo ==========================================
echo   🔧 本地环境诊断和修复
echo ==========================================
echo.

cd /d "%~dp0"

:: 步骤 1: 检查前端文件
echo [1/8] 检查前端文件...
if not exist "frontend\index-optimized.html" (
    echo ❌ frontend\index-optimized.html 不存在！
    pause
    exit /b 1
)

for %%F in ("frontend\index-optimized.html") do set SIZE=%%~zF
if %SIZE% LSS 100000 (
    echo ⚠️  index-optimized.html 文件太小 (%SIZE% bytes^)
) else (
    echo ✅ index-optimized.html 文件大小正常 (%SIZE% bytes^)
)

:: 步骤 2: 复制前端文件
echo.
echo [2/8] 更新前端文件...
copy /Y frontend\index-optimized.html frontend\index.html >nul
if exist PWA-manifest.json (
    copy /Y PWA-manifest.json frontend\manifest.json >nul
)
echo ✅ 前端文件已更新

:: 步骤 3: 检查环境变量
echo.
echo [3/8] 检查环境配置...
if not exist "backend\.env" (
    echo ⚠️  创建环境配置文件...
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
    type backend\.env
)

:: 步骤 4: 检查目录
echo.
echo [4/8] 检查目录结构...
if not exist "backend\data" mkdir backend\data
if not exist "ssl" mkdir ssl
echo ✅ 目录结构正常

:: 步骤 5: 停止现有服务
echo.
echo [5/8] 停止现有服务...
docker compose down
echo ✅ 服务已停止

:: 步骤 6: 重建并启动
echo.
echo [6/8] 重新构建服务...
echo 💡 这需要几分钟时间...
docker compose build --no-cache
if errorlevel 1 (
    echo ❌ 构建失败！
    pause
    exit /b 1
)

echo.
echo [7/8] 启动服务...
docker compose up -d
if errorlevel 1 (
    echo ❌ 启动失败！
    pause
    exit /b 1
)

:: 步骤 7: 等待启动
echo.
echo [8/8] 等待服务启动（40秒）...
timeout /t 40 /nobreak >nul

:: 显示状态
echo.
echo ==========================================
echo   📊 服务状态
echo ==========================================
docker compose ps

:: 查看日志
echo.
echo ==========================================
echo   📝 服务日志（最后20行）
echo ==========================================
docker compose logs --tail 20

:: 测试后端
echo.
echo ==========================================
echo   🧪 测试后端 API
echo ==========================================
curl -s http://localhost:8000/ 2>nul
if errorlevel 1 (
    echo ⚠️  后端 API 可能未响应
) else (
    echo ✅ 后端 API 正常
)

:: 测试前端
echo.
echo ==========================================
echo   🧪 测试前端
echo ==========================================
curl -I http://localhost/ 2>nul | findstr "200" >nul
if errorlevel 1 (
    echo ⚠️  前端可能未正常加载
) else (
    echo ✅ 前端加载正常
)

echo.
echo ==========================================
echo   📋 诊断完成
echo ==========================================
echo.
echo 🌐 请打开浏览器访问: http://localhost
echo 🔍 按 F12 打开开发者工具查看控制台
echo.
echo 💡 如果仍有问题，请提供：
echo   1. 浏览器控制台的错误信息
echo   2. docker compose logs backend 的输出
echo   3. 页面显示的截图
echo.

pause

