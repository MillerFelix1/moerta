"""
FastAPI 后端服务
提供阿里百炼智能体API调用和历史记录管理
"""
import os
import json
import uuid
from typing import Optional, Dict, Any
from http import HTTPStatus

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from dotenv import load_dotenv

# DashScope SDK 导入
try:
    from dashscope import Application
except ImportError:
    # 尝试新版本的导入方式
    try:
        from dashscope.app import Application
    except ImportError:
        # 如果还是不行，使用通用导入
        import dashscope
        Application = dashscope.Application

import database

# 加载环境变量
load_dotenv('.env')
load_dotenv('/app/.env')  # Docker 容器中的路径

app = FastAPI(title="数据解构专家测试平台")

# CORS配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境应该指定具体域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 配置
API_KEY = os.getenv("DASHSCOPE_API_KEY")
APP_ID = os.getenv("DASHSCOPE_APP_ID")


class ChatRequest(BaseModel):
    """聊天请求模型"""
    prompt: str
    session_id: Optional[str] = None
    stream: bool = True
    incremental_output: bool = True
    has_thoughts: bool = False


class SessionUpdateRequest(BaseModel):
    """会话更新请求"""
    title: str


@app.on_event("startup")
async def startup_event():
    """应用启动时初始化数据库"""
    await database.init_database()
    print("✅ 数据库初始化完成")


async def generate_session_title(prompt: str, response_text: str) -> str:
    """
    智能生成会话标题
    根据用户首次提问和AI回复生成简洁的标题
    """
    try:
        # 使用 AI 生成标题
        title_prompt = f"""根据以下对话内容，生成一个简洁的标题（不超过20个字）：

用户问题：{prompt[:100]}
AI回复：{response_text[:200]}

请直接返回标题，不要有任何解释。"""
        
        result = Application.call(
            api_key=API_KEY,
            app_id=APP_ID,
            prompt=title_prompt,
            stream=False
        )
        
        if result.status_code == HTTPStatus.OK:
            title = result.output.text.strip()
            # 清理标题
            title = title.replace('"', '').replace("'", '').replace('标题：', '').replace('标题:', '')
            if len(title) > 30:
                title = title[:30] + '...'
            return title if title else f"关于 {prompt[:10]}..."
    except Exception as e:
        print(f"生成标题失败: {e}")
    
    # 降级方案：使用用户问题前15个字
    return f"{prompt[:15]}..." if len(prompt) > 15 else prompt


@app.get("/")
async def root():
    """健康检查"""
    return {"status": "running", "service": "数据解构专家测试平台"}


@app.post("/api/chat")
async def chat(request: ChatRequest):
    """
    智能体对话接口
    支持流式输出和思考过程展示
    """
    try:
        # 生成或使用现有 session_id
        session_id = request.session_id or str(uuid.uuid4())
        
        # 先保存用户消息
        await database.save_message(
            session_id=session_id,
            role="user",
            content=request.prompt
        )
        
        # 调用阿里百炼API
        if request.stream:
            # 流式输出
            async def generate():
                full_text = ""
                full_thoughts = ""
                
                try:
                    responses = Application.call(
                        api_key=API_KEY,
                        app_id=APP_ID,
                        prompt=request.prompt,
                        session_id=session_id,
                        stream=True,
                        incremental_output=request.incremental_output,
                        has_thoughts=request.has_thoughts
                    )
                    
                    for response in responses:
                        if response.status_code != HTTPStatus.OK:
                            error_data = {
                                "error": "true",
                                "code": str(response.status_code),
                                "message": response.message,
                                "request_id": response.request_id
                            }
                            yield f"data: {json.dumps(error_data, ensure_ascii=False)}\n\n"
                            break
                        
                        # 获取文本内容
                        current_text = response.output.text
                        
                        # 累积完整内容（用于保存到数据库）
                        if not request.incremental_output:
                            full_text = current_text
                            if hasattr(response.output, 'thoughts'):
                                full_thoughts = response.output.thoughts or ""
                        else:
                            full_text += current_text
                            if hasattr(response.output, 'thoughts') and response.output.thoughts:
                                full_thoughts += response.output.thoughts
                        
                        # 构造响应数据
                        chunk_data = {
                            "text": current_text,
                            "session_id": session_id,
                            "finish_reason": getattr(response.output, 'finish_reason', None)
                        }
                        
                        if request.has_thoughts and hasattr(response.output, 'thoughts'):
                            chunk_data["thoughts"] = response.output.thoughts
                        
                        yield f"data: {json.dumps(chunk_data, ensure_ascii=False)}\n\n"
                    
                    # 保存助手回复到数据库
                    await database.save_message(
                        session_id=session_id,
                        role="assistant",
                        content=full_text,
                        thoughts=full_thoughts if full_thoughts else None
                    )
                    
                    # 如果是新会话，生成智能标题
                    if not request.session_id:
                        title = await generate_session_title(request.prompt, full_text)
                        await database.update_session_title(session_id, title)
                    
                except Exception as e:
                    error_data = {
                        "error": "true",
                        "message": str(e)
                    }
                    yield f"data: {json.dumps(error_data, ensure_ascii=False)}\n\n"
            
            return StreamingResponse(
                generate(),
                media_type="text/event-stream"
            )
        else:
            # 非流式输出
            response = Application.call(
                api_key=API_KEY,
                app_id=APP_ID,
                prompt=request.prompt,
                session_id=session_id,
                has_thoughts=request.has_thoughts
            )
            
            if response.status_code != HTTPStatus.OK:
                raise HTTPException(
                    status_code=response.status_code,
                    detail={
                        "message": response.message,
                        "request_id": response.request_id
                    }
                )
            
            # 保存助手回复
            await database.save_message(
                session_id=session_id,
                role="assistant",
                content=response.output.text,
                thoughts=getattr(response.output, 'thoughts', None)
            )
            
            # 如果是新会话，生成智能标题
            if not request.session_id:
                title = await generate_session_title(request.prompt, response.output.text)
                await database.update_session_title(session_id, title)
            
            result = {
                "text": response.output.text,
                "session_id": session_id
            }
            
            if request.has_thoughts and hasattr(response.output, 'thoughts'):
                result["thoughts"] = response.output.thoughts
            
            return result
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/sessions")
async def get_sessions():
    """获取所有会话列表"""
    try:
        sessions = await database.get_all_sessions()
        return {"sessions": sessions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/sessions/{session_id}")
async def get_session_detail(session_id: str):
    """获取会话详情（所有消息）"""
    try:
        messages = await database.get_session_messages(session_id)
        return {"session_id": session_id, "messages": messages}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.put("/api/sessions/{session_id}")
async def update_session(session_id: str, request: SessionUpdateRequest):
    """更新会话标题"""
    try:
        await database.update_session_title(session_id, request.title)
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/api/sessions/{session_id}")
async def delete_session(session_id: str):
    """删除会话"""
    try:
        await database.delete_session(session_id)
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/search")
async def search(keyword: str):
    """搜索历史消息"""
    try:
        results = await database.search_messages(keyword)
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/export/{session_id}")
async def export_session(session_id: str, format: str = "markdown"):
    """
    导出会话
    支持格式: markdown, json, txt
    """
    try:
        from fastapi.responses import Response
        import json as json_module
        
        messages = await database.get_session_messages(session_id)
        
        if format == "markdown":
            content = f"# Memory Reconstruction - 对话导出\n\n"
            for msg in messages:
                role = "👤 用户" if msg['role'] == 'user' else "🤖 AI助手"
                content += f"## {role}\n\n{msg['content']}\n\n"
                if msg.get('thoughts'):
                    content += f"**💭 思考过程:**\n\n{msg['thoughts']}\n\n"
                content += "---\n\n"
            return Response(content=content, media_type="text/markdown", 
                          headers={"Content-Disposition": f"attachment; filename=conversation-{session_id}.md"})
        
        elif format == "json":
            content = json_module.dumps(messages, ensure_ascii=False, indent=2)
            return Response(content=content, media_type="application/json",
                          headers={"Content-Disposition": f"attachment; filename=conversation-{session_id}.json"})
        
        elif format == "txt":
            content = ""
            for msg in messages:
                role = "用户" if msg['role'] == 'user' else "AI助手"
                content += f"[{role}]\n{msg['content']}\n\n"
                if msg.get('thoughts'):
                    content += f"[思考过程]\n{msg['thoughts']}\n\n"
                content += "-" * 50 + "\n\n"
            return Response(content=content, media_type="text/plain",
                          headers={"Content-Disposition": f"attachment; filename=conversation-{session_id}.txt"})
        
        else:
            raise HTTPException(status_code=400, detail="不支持的格式")
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/stats")
async def get_stats():
    """获取统计信息"""
    try:
        sessions = await database.get_all_sessions()
        total_sessions = len(sessions)
        total_messages = sum(s['message_count'] for s in sessions)
        
        return {
            "total_sessions": total_sessions,
            "total_messages": total_messages,
            "avg_messages_per_session": total_messages / total_sessions if total_sessions > 0 else 0
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    
    print(f"🚀 启动服务器: http://{host}:{port}")
    uvicorn.run(app, host=host, port=port)

