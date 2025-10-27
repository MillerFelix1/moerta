# Memory Reconstruction Platform - Makefile
# 简化 Docker 操作的快捷命令

.PHONY: help build up down restart logs shell test clean deploy

# 默认目标
help:
	@echo "Memory Reconstruction Platform - Docker 命令"
	@echo ""
	@echo "使用方法: make [命令]"
	@echo ""
	@echo "可用命令:"
	@echo "  build      - 构建 Docker 镜像"
	@echo "  up         - 启动所有服务"
	@echo "  down       - 停止所有服务"
	@echo "  restart    - 重启所有服务"
	@echo "  logs       - 查看日志"
	@echo "  shell      - 进入后端容器"
	@echo "  test       - 测试 API 连接"
	@echo "  clean      - 清理所有容器和镜像"
	@echo "  deploy     - 完整部署（构建+启动）"
	@echo "  backup     - 备份数据库"
	@echo ""

# 构建镜像
build:
	@echo "🔨 构建 Docker 镜像..."
	docker compose build

# 启动服务
up:
	@echo "🚀 启动服务..."
	docker compose up -d
	@echo "✅ 服务已启动"
	@echo "访问: http://localhost"

# 停止服务
down:
	@echo "🛑 停止服务..."
	docker compose down
	@echo "✅ 服务已停止"

# 重启服务
restart:
	@echo "🔄 重启服务..."
	docker compose restart
	@echo "✅ 服务已重启"

# 查看日志
logs:
	docker compose logs -f

# 进入容器
shell:
	docker compose exec backend bash

# 测试 API
test:
	@echo "🧪 测试 API 连接..."
	@curl -s http://localhost:8000/ | grep -q "running" && echo "✅ API 正常" || echo "❌ API 异常"

# 清理
clean:
	@echo "🧹 清理容器和镜像..."
	docker compose down --rmi all -v
	@echo "✅ 清理完成"

# 完整部署
deploy: build up
	@echo "🎉 部署完成！"
	@echo "访问: http://localhost"

# 备份数据库
backup:
	@echo "💾 备份数据库..."
	@mkdir -p backups
	@cp backend/data/history.db backups/history_$(shell date +%Y%m%d_%H%M%S).db
	@echo "✅ 备份完成: backups/history_$(shell date +%Y%m%d_%H%M%S).db"

# 查看状态
status:
	@docker compose ps

