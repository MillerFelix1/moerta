@echo off
chcp 65001 >nul

:: ===================================
:: 本地快速更新脚本
:: ===================================

echo.
echo ==========================================
echo   🔄 本地快速更新
echo ==========================================
echo.

echo 请选择更新类型:
echo.
echo   1. 前端更新（最快，3秒）
echo   2. 后端更新（使用缓存，30-60秒）
echo   3. 完全重建（无缓存，3-5分钟）
echo   4. 退出
echo.

set /p "CHOICE=请选择 [1-4]: "

if "%CHOICE%"=="1" goto UPDATE_FRONTEND
if "%CHOICE%"=="2" goto UPDATE_BACKEND
if "%CHOICE%"=="3" goto REBUILD_ALL
if "%CHOICE%"=="4" goto END

echo ❌ 无效选择
goto END

:UPDATE_FRONTEND
echo.
echo 📝 更新前端文件...
copy /Y frontend\index-optimized.html frontend\index.html >nul
docker compose restart nginx
echo.
echo ✅ 前端已更新！访问 http://localhost 查看
goto END

:UPDATE_BACKEND
echo.
echo 🔨 重建后端（使用缓存）...
docker compose build backend
docker compose up -d backend
echo.
echo ✅ 后端已更新！
goto END

:REBUILD_ALL
echo.
echo 🔨 完全重建所有服务...
echo ⚠️  这需要几分钟时间
docker compose down
docker compose up -d --build
echo.
echo ⏳ 等待服务启动（30秒）...
timeout /t 30 /nobreak >nul
echo.
echo ✅ 重建完成！
goto END

:END
echo.
pause

