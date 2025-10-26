#!/bin/bash

# Memory Reconstruction 测试平台 - 服务器部署脚本
# 适用于 Alibaba Cloud Linux 3 / RHEL / CentOS 系统

set -e  # 遇到错误立即退出

echo "========================================="
echo "  数据解构专家 - 服务器部署脚本"
echo "========================================="
echo ""

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 请使用root权限运行此脚本"
    echo "   使用命令: sudo bash deploy.sh"
    exit 1
fi

# 配置变量
DOMAIN="shangyu.icu"
PROJECT_DIR="/var/www/${DOMAIN}"

# 检测系统并设置正确的用户
if grep -qi "Alibaba Cloud Linux" /etc/os-release 2>/dev/null || grep -qi "Alinux" /etc/os-release 2>/dev/null; then
    SERVICE_USER="nginx"
    NGINX_PACKAGE="aa_nginx"
    echo "检测到阿里云 Linux 系统"
else
    SERVICE_USER="www-data"
    NGINX_PACKAGE="nginx"
fi

echo "📋 配置信息:"
echo "   域名: ${DOMAIN}"
echo "   项目目录: ${PROJECT_DIR}"
echo "   运行用户: ${SERVICE_USER}"
echo ""

# 1. 安装系统依赖
echo "📦 步骤 1/7: 安装系统依赖..."

# 检查使用 yum 还是 dnf
if command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
else
    PKG_MANAGER="yum"
fi

echo "使用包管理器: ${PKG_MANAGER}"

# 检查并安装 EPEL 仓库（阿里云可能已预装）
if ! rpm -q epel-release &> /dev/null && ! rpm -q epel-aliyuncs-release &> /dev/null; then
    echo "安装 EPEL 仓库..."
    ${PKG_MANAGER} install -y epel-release
else
    echo "EPEL 仓库已存在，跳过安装"
fi

# 安装系统依赖
${PKG_MANAGER} install -y git curl gcc

# 检查 Python 版本并安装合适的版本
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
echo "当前 Python 版本: ${PYTHON_VERSION}"

if [ "${PYTHON_VERSION}" == "3.6" ]; then
    echo "⚠️  Python 3.6 太旧，尝试安装 Python 3.9..."
    # 阿里云 Linux 3 支持 Python 3.9
    ${PKG_MANAGER} install -y python39 python39-pip python39-devel
    # 设置 python3 别名
    alternatives --set python3 /usr/bin/python3.9 2>/dev/null || true
    # 升级 pip
    python3.9 -m pip install --upgrade pip
    PYTHON_CMD="python3.9"
else
    ${PKG_MANAGER} install -y python3 python3-pip python3-devel
    PYTHON_CMD="python3"
fi

echo "使用 Python: $(${PYTHON_CMD} --version)"

# 安装 Nginx（阿里云使用特殊包名）
if ! command -v nginx &> /dev/null; then
    echo "安装 Nginx..."
    ${PKG_MANAGER} install -y ${NGINX_PACKAGE} --enablerepo=alinux3-updates 2>/dev/null || \
    ${PKG_MANAGER} install -y nginx
else
    echo "Nginx 已安装"
fi

# 安装 Python 虚拟环境（如果需要）
${PKG_MANAGER} install -y python3-virtualenv 2>/dev/null || pip3 install virtualenv

echo "✅ 系统依赖安装完成"
echo ""

# 2. 检测并设置项目目录
echo "📁 步骤 2/7: 检查项目目录..."

# 检测实际的项目路径（可能在 yuanshi 子目录中）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ACTUAL_PROJECT_DIR="$( cd "${SCRIPT_DIR}/.." && pwd )"

echo "脚本位置: ${SCRIPT_DIR}"
echo "检测到项目目录: ${ACTUAL_PROJECT_DIR}"

# 如果实际目录和配置目录不同，使用实际目录
if [ "${ACTUAL_PROJECT_DIR}" != "${PROJECT_DIR}" ]; then
    echo "⚠️  注意: 使用实际项目目录 ${ACTUAL_PROJECT_DIR}"
    PROJECT_DIR="${ACTUAL_PROJECT_DIR}"
fi

# 验证项目文件
if [ ! -f "${PROJECT_DIR}/backend/server.py" ]; then
    echo "❌ 错误: 未找到项目文件"
    echo "   期望位置: ${PROJECT_DIR}/backend/server.py"
    echo "   当前目录: $(pwd)"
    echo "   请检查项目结构"
    exit 1
fi

echo "✅ 项目目录确认: ${PROJECT_DIR}"
echo ""

# 3. 安装Python依赖
echo "🐍 步骤 3/7: 安装Python依赖..."
cd ${PROJECT_DIR}/backend

# 使用正确的 Python 版本
if command -v python3.9 &> /dev/null; then
    echo "使用 Python 3.9 安装依赖..."
    python3.9 -m pip install -r requirements.txt
else
    pip3 install -r requirements.txt
fi

echo "✅ Python依赖安装完成"
echo ""

# 4. 配置环境变量
echo "⚙️  步骤 4/7: 配置环境变量..."
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "⚠️  已创建 .env 文件，请检查配置!"
    else
        echo "❌ 未找到 .env.example 文件"
        exit 1
    fi
fi

# 创建数据目录
mkdir -p ${PROJECT_DIR}/backend/data

echo "✅ 环境变量配置完成"
echo ""

# 5. 配置systemd服务
echo "🔧 步骤 5/7: 配置systemd服务..."
cp ${PROJECT_DIR}/deploy/systemd.service /etc/systemd/system/data-expert.service

# 修改配置文件中的路径
sed -i "s|/var/www/shangyu.icu|${PROJECT_DIR}|g" /etc/systemd/system/data-expert.service

# 重新加载systemd
systemctl daemon-reload

# 启动服务
systemctl enable data-expert
systemctl start data-expert

# 检查服务状态
if systemctl is-active --quiet data-expert; then
    echo "✅ 后端服务启动成功"
else
    echo "❌ 后端服务启动失败，请检查日志:"
    echo "   journalctl -u data-expert -n 50"
    exit 1
fi

echo ""

# 6. 配置Nginx
echo "🌐 步骤 6/7: 配置Nginx..."

# 检测 Nginx 配置目录结构
if [ -d "/etc/nginx/conf.d" ]; then
    # RHEL/CentOS/Alibaba Cloud Linux 使用 conf.d
    NGINX_CONF_DIR="/etc/nginx/conf.d"
    cp ${PROJECT_DIR}/deploy/nginx.conf ${NGINX_CONF_DIR}/${DOMAIN}.conf
    sed -i "s|/var/www/shangyu.icu|${PROJECT_DIR}|g" ${NGINX_CONF_DIR}/${DOMAIN}.conf
    echo "Nginx 配置已复制到: ${NGINX_CONF_DIR}/${DOMAIN}.conf"
elif [ -d "/etc/nginx/sites-available" ]; then
    # Ubuntu/Debian 使用 sites-available
    NGINX_CONF_DIR="/etc/nginx/sites-available"
    cp ${PROJECT_DIR}/deploy/nginx.conf ${NGINX_CONF_DIR}/${DOMAIN}
    sed -i "s|/var/www/shangyu.icu|${PROJECT_DIR}|g" ${NGINX_CONF_DIR}/${DOMAIN}
    ln -sf ${NGINX_CONF_DIR}/${DOMAIN} /etc/nginx/sites-enabled/
    echo "Nginx 配置已复制到: ${NGINX_CONF_DIR}/${DOMAIN}"
else
    echo "❌ 未找到 Nginx 配置目录"
    exit 1
fi

# 测试nginx配置
if nginx -t; then
    # 确保 Nginx 已启动
    systemctl enable nginx
    systemctl start nginx 2>/dev/null || true
    systemctl reload nginx
    echo "✅ Nginx配置成功"
else
    echo "❌ Nginx配置有误，请检查"
    exit 1
fi

echo ""

# 7. 设置文件权限
echo "🔒 步骤 7/7: 设置文件权限..."
chown -R ${SERVICE_USER}:${SERVICE_USER} ${PROJECT_DIR}
chmod -R 755 ${PROJECT_DIR}
chmod -R 777 ${PROJECT_DIR}/backend/data

echo "✅ 文件权限设置完成"
echo ""

# 8. 配置防火墙（可选）
echo "🔥 配置防火墙..."
if command -v firewall-cmd &> /dev/null; then
    # RHEL/CentOS 使用 firewalld
    systemctl start firewalld
    systemctl enable firewalld
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --permanent --add-port=8000/tcp
    firewall-cmd --reload
    echo "✅ 防火墙规则已添加 (firewalld)"
elif command -v ufw &> /dev/null; then
    # Ubuntu/Debian 使用 ufw
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 8000/tcp
    echo "✅ 防火墙规则已添加 (ufw)"
else
    echo "⚠️  未找到防火墙管理工具，请手动配置"
fi

echo ""

# 9. 配置SSL证书（可选）
echo "🔐 配置SSL证书..."
read -p "是否安装SSL证书? (y/n): " install_ssl

if [ "$install_ssl" = "y" ]; then
    # 安装 certbot
    ${PKG_MANAGER} install -y certbot python3-certbot-nginx
    
    # 申请证书
    certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}
    
    # 设置自动续期
    if ! systemctl list-timers | grep -q certbot; then
        # 创建定时任务
        echo "0 0,12 * * * root certbot renew --quiet" >> /etc/crontab
    fi
    
    echo "✅ SSL证书安装完成"
else
    echo "⚠️  跳过SSL证书安装"
    echo "   以后可以使用命令: certbot --nginx -d ${DOMAIN}"
fi

echo ""
echo "========================================="
echo "  🎉 部署完成！"
echo "========================================="
echo ""
echo "📍 访问地址:"
echo "   HTTP:  http://${DOMAIN}"
if [ "$install_ssl" = "y" ]; then
    echo "   HTTPS: https://${DOMAIN}"
fi
echo ""
echo "🔍 查看服务状态:"
echo "   systemctl status data-expert"
echo ""
echo "📋 查看日志:"
echo "   journalctl -u data-expert -f"
echo ""
echo "🔄 重启服务:"
echo "   systemctl restart data-expert"
echo ""
echo "⚠️  请检查:"
echo "   1. 修改 ${PROJECT_DIR}/backend/.env 中的配置"
echo "   2. 确保域名 ${DOMAIN} 已解析到服务器IP"
echo "   3. 测试访问网站功能是否正常"
echo ""
echo "========================================="

