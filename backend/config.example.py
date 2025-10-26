"""
配置文件示例
生产环境部署时的额外配置选项
"""

# API配置
DASHSCOPE_API_KEY = "sk-31d4c4895a6d4a959fa9f4ff029515ac"
APP_ID = "6596ab6827f445f08abc4194be485bc1"

# 服务器配置
HOST = "0.0.0.0"
PORT = 8000

# 数据库配置
DATABASE_PATH = "./data/history.db"

# CORS配置
ALLOWED_ORIGINS = [
    "http://shangyu.icu",
    "https://shangyu.icu",
    "http://www.shangyu.icu",
    "https://www.shangyu.icu",
    "http://localhost:3000",
    "http://127.0.0.1:3000",
]

# 日志配置
LOG_LEVEL = "INFO"
LOG_FILE = "./logs/app.log"

# 性能配置
MAX_WORKERS = 4
REQUEST_TIMEOUT = 300  # 秒

# 安全配置
RATE_LIMIT = "100/hour"  # 每小时最多100次请求（可选实现）

