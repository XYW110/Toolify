#!/usr/bin/env python3
"""
测试代理路由的非流式请求转发功能
"""

import requests
import json
import time

def test_proxy_non_streaming():
    """测试代理路由的非流式请求转发"""
    print("🚀 测试代理路由 - 非流式请求转发...")
    print("=" * 60)
    
    # 测试1: 基本非流式聊天完成请求
    print("测试1: 基本非流式聊天完成请求")
    try:
        response = requests.post(
            'http://localhost:8000/proxy?targetHost=api.openai.com&path=/v1/chat/completions',
            headers={'Authorization': 'Bearer sk-my-secret-key-1'},
            json={
                'model': 'gpt-3.5-turbo',
                'messages': [{'role': 'user', 'content': 'Hello!'}],
                'stream': False  # 明确指定非流式
            }
        )
        print(f"状态码: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ 请求成功")
            print("📊 返回结果:")
            print(json.dumps(result, indent=2, ensure_ascii=False))
            
            # 验证响应格式
            if 'choices' in result and len(result['choices']) > 0:
                print("✅ 响应包含 choices 字段")
                choice = result['choices'][0]
                if 'message' in choice and 'content' in choice['message']:
                    print("✅ 响应包含 message.content 字段")
                elif 'message' in choice and 'tool_calls' in choice['message']:
                    print("✅ 响应包含 tool_calls 字段")
                else:
                    print("⚠️  响应格式异常")
            
            if 'usage' in result:
                usage = result['usage']
                print(f"📊 Token 使用统计:")
                print(f"   输入 Tokens: {usage.get('prompt_tokens', 0)}")
                print(f"   输出 Tokens: {usage.get('completion_tokens', 0)}")
                print(f"   总 Tokens: {usage.get('total_tokens', 0)}")
            else:
                print("⚠️  未找到 usage 字段")
                
        else:
            print("❌ 状态码不是200")
            print("内容:", response.text[:300])
            
    except Exception as e:
        print(f"❌ 请求失败: {e}")
    
    print()
    print("=" * 60)
    
    # 测试2: 非流式请求（默认，不指定stream字段）
    print("测试2: 非流式请求（默认，不指定stream字段）")
    try:
        response = requests.post(
            'http://localhost:8000/proxy?targetHost=api.openai.com&path=/v1/chat/completions',
            headers={'Authorization': 'Bearer sk-my-secret-key-1'},
            json={
                'model': 'gpt-3.5-turbo',
                'messages': [{'role': 'user', 'content': 'Tell me a joke.'}]
                # 不指定 stream 字段，默认为 False
            }
        )
        print(f"状态码: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ 请求成功")
            print("📊 返回结果:")
            print(json.dumps(result, indent=2, ensure_ascii=False)[:500] + "..." if len(json.dumps(result)) > 500 else json.dumps(result, indent=2, ensure_ascii=False))
            
            # 验证响应格式
            if 'choices' in result and len(result['choices']) > 0:
                print("✅ 响应包含 choices 字段")
                choice = result['choices'][0]
                if 'message' in choice and 'content' in choice['message']:
                    content = choice['message']['content']
                    print(f"✅ 助手回复: {content[:100]}..." if len(content) > 100 else f"✅ 助手回复: {content}")
                elif 'message' in choice and 'tool_calls' in choice['message']:
                    print("✅ 检测到工具调用")
                else:
                    print("⚠️  响应格式异常")
            else:
                print("⚠️  未找到 choices 字段")
                
        else:
            print("❌ 状态码不是200")
            print("内容:", response.text[:300])
            
    except Exception as e:
        print(f"❌ 请求失败: {e}")
    
    print()
    print("=" * 60)
    
    # 测试3: 错误处理 - 无效的模型
    print("测试3: 错误处理 - 无效的模型")
    try:
        response = requests.post(
            'http://localhost:8000/proxy?targetHost=api.openai.com&path=/v1/chat/completions',
            headers={'Authorization': 'Bearer sk-my-secret-key-1'},
            json={
                'model': 'invalid-model-name',
                'messages': [{'role': 'user', 'content': 'Hello!'}],
                'stream': False
            }
        )
        print(f"状态码: {response.status_code}")
        
        if response.status_code == 400:
            result = response.json()
            print("✅ 正确返回400错误")
            print("错误信息:", result.get('error', {}).get('message', '未知错误'))
        else:
            print("⚠️  状态码:", response.status_code)
            print("内容:", response.text[:200])
            
    except Exception as e:
        print(f"❌ 请求失败: {e}")
    
    print()
    print("=" * 60)
    print("🎉 非流式请求转发测试完成！")

if __name__ == "__main__":
    test_proxy_non_streaming()