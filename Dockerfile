# ===================================
# Memory Reconstruction Platform
# Docker 镜像 v2.0
# ===================================

FROM python:3.11-slim

# 元数据
LABEL maintainer="Memory Reconstruction Team"
LABEL version="2.0"
LABEL description="AI-powered memory reconstruction platform"

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# 安装系统依赖（包含 curl 用于健康检查）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 复制依赖文件
COPY backend/requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt && \
    pip list

# 复制项目文件
COPY backend/ .

# 创建数据目录并设置权限
RUN mkdir -p /app/data && \
    chmod 755 /app/data

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["python", "-u", "server.py"]

