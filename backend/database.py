"""
数据库操作模块
使用 SQLite 存储对话历史
"""
import aiosqlite
import json
from datetime import datetime
from typing import List, Dict, Optional
import os

DATABASE_PATH = os.getenv("DATABASE_PATH", "./data/history.db")


async def init_database():
    """初始化数据库表结构"""
    # 确保数据目录存在
    os.makedirs(os.path.dirname(DATABASE_PATH), exist_ok=True)
    
    async with aiosqlite.connect(DATABASE_PATH) as db:
        # 创建会话表
        await db.execute("""
            CREATE TABLE IF NOT EXISTS sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT UNIQUE NOT NULL,
                title TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # 创建消息表
        await db.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                role TEXT NOT NULL,
                content TEXT NOT NULL,
                thoughts TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (session_id) REFERENCES sessions(session_id)
            )
        """)
        
        # 创建索引
        await db.execute("""
            CREATE INDEX IF NOT EXISTS idx_session_id ON messages(session_id)
        """)
        await db.execute("""
            CREATE INDEX IF NOT EXISTS idx_created_at ON messages(created_at)
        """)
        
        await db.commit()


async def save_message(
    session_id: str,
    role: str,
    content: str,
    thoughts: Optional[str] = None,
    title: Optional[str] = None
):
    """保存单条消息"""
    async with aiosqlite.connect(DATABASE_PATH) as db:
        # 确保会话存在
        await db.execute("""
            INSERT OR IGNORE INTO sessions (session_id, title)
            VALUES (?, ?)
        """, (session_id, title or "新对话"))
        
        # 更新会话时间
        await db.execute("""
            UPDATE sessions 
            SET updated_at = CURRENT_TIMESTAMP
            WHERE session_id = ?
        """, (session_id,))
        
        # 保存消息
        await db.execute("""
            INSERT INTO messages (session_id, role, content, thoughts)
            VALUES (?, ?, ?, ?)
        """, (session_id, role, content, thoughts))
        
        await db.commit()


async def get_session_messages(session_id: str) -> List[Dict]:
    """获取会话的所有消息"""
    async with aiosqlite.connect(DATABASE_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("""
            SELECT role, content, thoughts, created_at
            FROM messages
            WHERE session_id = ?
            ORDER BY created_at ASC
        """, (session_id,)) as cursor:
            rows = await cursor.fetchall()
            return [dict(row) for row in rows]


async def get_all_sessions() -> List[Dict]:
    """获取所有会话列表"""
    async with aiosqlite.connect(DATABASE_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("""
            SELECT s.session_id, s.title, s.created_at, s.updated_at,
                   COUNT(m.id) as message_count
            FROM sessions s
            LEFT JOIN messages m ON s.session_id = m.session_id
            GROUP BY s.session_id
            ORDER BY s.updated_at DESC
        """) as cursor:
            rows = await cursor.fetchall()
            return [dict(row) for row in rows]


async def delete_session(session_id: str):
    """删除会话及其所有消息"""
    async with aiosqlite.connect(DATABASE_PATH) as db:
        await db.execute("DELETE FROM messages WHERE session_id = ?", (session_id,))
        await db.execute("DELETE FROM sessions WHERE session_id = ?", (session_id,))
        await db.commit()


async def update_session_title(session_id: str, title: str):
    """更新会话标题"""
    async with aiosqlite.connect(DATABASE_PATH) as db:
        await db.execute("""
            UPDATE sessions 
            SET title = ?
            WHERE session_id = ?
        """, (title, session_id))
        await db.commit()


async def search_messages(keyword: str) -> List[Dict]:
    """搜索包含关键词的消息"""
    async with aiosqlite.connect(DATABASE_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("""
            SELECT m.*, s.title
            FROM messages m
            JOIN sessions s ON m.session_id = s.session_id
            WHERE m.content LIKE ?
            ORDER BY m.created_at DESC
            LIMIT 100
        """, (f"%{keyword}%",)) as cursor:
            rows = await cursor.fetchall()
            return [dict(row) for row in rows]

