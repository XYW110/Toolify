#!/usr/bin/env python3
"""
测试 _process_chat_request 辅助函数
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import asyncio
from main import _process_chat_request, ChatCompletionRequest

async def test_process_chat_request():
    """测试新的辅助函数"""
    print("🧪 测试 _process_chat_request 辅助函数...")
    
    # 创建一个简单的测试请求
    test_body = ChatCompletionRequest(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "user", "content": "Hello, how are you?"}
        ]
    )
    
    try:
        # 调用辅助函数
        result = await _process_chat_request(test_body, "test-api-key")
        
        print("✅ 辅助函数调用成功！")
        print(f"📋 返回结果包含以下键: {list(result.keys())}")
        
        # 验证返回的数据结构
        required_keys = ["upstream_url", "request_body", "headers", "has_function_call", "prompt_tokens"]
        for key in required_keys:
            if key in result:
                print(f"   ✅ {key}: {type(result[key]).__name__}")
            else:
                print(f"   ❌ 缺少必需的键: {key}")
                return False
        
        # 验证具体内容
        print(f"   🔗 upstream_url: {result['upstream_url']}")
        print(f"   📝 request_body keys: {list(result['request_body'].keys())}")
        print(f"   🛡️  headers keys: {list(result['headers'].keys())}")
        print(f"   🎯 has_function_call: {result['has_function_call']}")
        print(f"   📊 prompt_tokens: {result['prompt_tokens']}")
        
        print("\n🎉 所有测试通过！辅助函数工作正常。")
        return True
        
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(test_process_chat_request())
    sys.exit(0 if success else 1)