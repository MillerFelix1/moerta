@echo off
chcp 65001 >nul

:: ===================================
:: 部署到服务器脚本
:: ===================================

echo.
echo ==========================================
echo   🚀 部署到生产服务器
echo ==========================================
echo.

echo ⚠️  警告：这将把当前本地代码部署到生产服务器！
echo.
echo 部署步骤：
echo   1. 提交本地修改到 Git
echo   2. 推送到 GitHub
echo   3. SSH 到服务器
echo   4. 拉取最新代码
echo   5. 智能更新服务
echo.

set /p "CONFIRM=确认部署？(Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo 已取消
    pause
    exit /b 0
)

echo.
echo ==========================================
echo   步骤 1: Git 提交
echo ==========================================
echo.

:: 检查是否有 git
git --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Git 未安装！
    echo.
    echo 请手动执行以下步骤：
    echo   1. 打开 Git Bash
    echo   2. cd /d/yuanshi
    echo   3. git add .
    echo   4. git commit -m "你的提交信息"
    echo   5. git push origin main
    echo   6. ssh admin@8.137.51.166
    echo   7. cd /var/www/shangyu.icu/yuanshi
    echo   8. git pull
    echo   9. bash smart-update.sh
    echo.
    pause
    exit /b 1
)

:: 显示当前状态
echo 📋 当前修改:
git status -s
echo.

set /p "COMMIT_MSG=请输入提交信息: "
if "%COMMIT_MSG%"=="" (
    echo ❌ 提交信息不能为空
    pause
    exit /b 1
)

:: Git 操作
echo.
echo 正在提交...
git add .
git commit -m "%COMMIT_MSG%"

if errorlevel 1 (
    echo ⚠️  没有需要提交的修改或提交失败
)

echo.
echo 正在推送到 GitHub...
git push origin main

if errorlevel 1 (
    echo ❌ 推送失败！
    echo 请检查网络连接和 Git 配置
    pause
    exit /b 1
)

echo ✅ 代码已推送到 GitHub

echo.
echo ==========================================
echo   步骤 2: 服务器部署
echo ==========================================
echo.

echo 📋 服务器信息:
echo   IP: 8.137.51.166
echo   用户: admin
echo   项目: /var/www/shangyu.icu/yuanshi
echo.

echo 💡 请手动执行以下命令（会在新窗口打开）:
echo.
echo   ssh admin@8.137.51.166
echo   cd /var/www/shangyu.icu/yuanshi
echo   git pull
echo   bash smart-update.sh
echo   bash check-system.sh
echo.

:: 创建临时 SSH 命令文件
(
    echo @echo off
    echo echo 连接到服务器...
    echo echo.
    echo ssh admin@8.137.51.166
) > %TEMP%\deploy_ssh.bat

:: 打开新窗口执行 SSH
start "SSH 到服务器" %TEMP%\deploy_ssh.bat

echo.
echo ✅ 本地部署准备完成！
echo 💡 请在新打开的窗口中完成服务器部署
echo.

pause

