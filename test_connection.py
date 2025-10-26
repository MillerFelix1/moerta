"""
快速测试脚本 - 验证API配置是否正确
运行此脚本检查阿里百炼API连接
"""
import os
from http import HTTPStatus
from dashscope import Application

# API配置
API_KEY = "sk-31d4c4895a6d4a959fa9f4ff029515ac"
APP_ID = "6596ab6827f445f08abc4194be485bc1"

def test_api_connection():
    """测试API连接"""
    print("=" * 50)
    print("  阿里百炼API连接测试")
    print("=" * 50)
    print()
    
    print(f"API Key: {API_KEY[:20]}...")
    print(f"App ID: {APP_ID}")
    print()
    
    print("🔄 正在发送测试请求...")
    print()
    
    try:
        response = Application.call(
            api_key=API_KEY,
            app_id=APP_ID,
            prompt='你好，请简单介绍一下你自己。'
        )
        
        if response.status_code != HTTPStatus.OK:
            print("❌ 请求失败!")
            print(f"   状态码: {response.status_code}")
            print(f"   错误信息: {response.message}")
            print(f"   Request ID: {response.request_id}")
            print()
            print("📖 参考文档: https://help.aliyun.com/zh/model-studio/developer-reference/error-code")
            return False
        
        print("✅ API连接成功!")
        print()
        print("📄 响应内容:")
        print("-" * 50)
        print(response.output.text)
        print("-" * 50)
        print()
        
        if hasattr(response.output, 'session_id'):
            print(f"📌 Session ID: {response.output.session_id}")
        
        print()
        print("✨ 所有测试通过! 可以开始使用测试平台了。")
        return True
        
    except Exception as e:
        print("❌ 发生错误!")
        print(f"   错误类型: {type(e).__name__}")
        print(f"   错误信息: {str(e)}")
        print()
        print("💡 可能的原因:")
        print("   1. API Key 或 App ID 不正确")
        print("   2. 网络连接问题")
        print("   3. DashScope SDK 未安装或版本过旧")
        print()
        print("🔧 解决方案:")
        print("   1. 检查 backend/.env 文件中的配置")
        print("   2. 确认网络可以访问阿里云服务")
        print("   3. 运行: pip install -U dashscope")
        return False

def test_stream_output():
    """测试流式输出"""
    print()
    print("=" * 50)
    print("  测试流式输出")
    print("=" * 50)
    print()
    
    print("🔄 正在发送流式请求...")
    print()
    print("📄 响应内容 (流式):")
    print("-" * 50)
    
    try:
        responses = Application.call(
            api_key=API_KEY,
            app_id=APP_ID,
            prompt='用一句话介绍一下你的主要功能。',
            stream=True,
            incremental_output=True
        )
        
        full_text = ""
        for response in responses:
            if response.status_code != HTTPStatus.OK:
                print(f"\n❌ 流式请求失败: {response.message}")
                return False
            
            print(response.output.text, end='', flush=True)
            full_text += response.output.text
        
        print()
        print("-" * 50)
        print()
        print("✅ 流式输出测试成功!")
        return True
        
    except Exception as e:
        print(f"\n❌ 流式输出测试失败: {str(e)}")
        return False

if __name__ == "__main__":
    # 测试基本连接
    basic_test = test_api_connection()
    
    # 如果基本测试通过，继续测试流式输出
    if basic_test:
        test_stream_output()
    
    print()
    print("=" * 50)
    print("  测试完成")
    print("=" * 50)

