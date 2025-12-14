#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试代理路由的流式请求转发功能
"""

import requests
import json
import time

def test_proxy_streaming():
    """测试代理路由的流式请求转发"""
    print('🚀 测试代理路由流式请求转发功能...')
    print('=' * 60)
    
    # 测试1: 流式请求 - 基本聊天
    print('测试1: 流式请求 - 基本聊天')
    try:
        response = requests.post(
            'http://localhost:8000/proxy?targetHost=api.openai.com&path=/v1/chat/completions',
            headers={
                'Authorization': 'Bearer sk-my-secret-key-1',
                'Content-Type': 'application/json'
            },
            json={
                'model': 'gpt-3.5-turbo',
                'messages': [{'role': 'user', 'content': 'Hello! Please respond briefly.'}],
                'stream': True,
                'max_tokens': 50
            },
            stream=True
        )
        
        print(f'状态码: {response.status_code}')
        print(f'Content-Type: {response.headers.get("content-type")}')
        
        if response.status_code == 200:
            print('✅ 流式请求成功启动')
            print('📊 流式响应内容:')
            
            chunk_count = 0
            for line in response.iter_lines():
                if line:
                    line_str = line.decode('utf-8')
                    print(f'  {line_str}')
                    chunk_count += 1
                    
                    # 限制输出数量，避免过多内容
                    if chunk_count >= 10:
                        print('  ... (更多内容省略)')
                        break
            
            print(f'✅ 接收到 {chunk_count} 个数据块')
        else:
            print(f'❌ 状态码不是200: {response.status_code}')
            print(f'错误内容: {response.text[:200]}')
            
    except Exception as e:
        print(f'❌ 请求失败: {e}')
    
    print()
    print('=' * 60)
    
    # 测试2: 非流式请求对比
    print('测试2: 非流式请求对比')
    try:
        response = requests.post(
            'http://localhost:8000/proxy?targetHost=api.openai.com&path=/v1/chat/completions',
            headers={
                'Authorization': 'Bearer sk-my-secret-key-1',
                'Content-Type': 'application/json'
            },
            json={
                'model': 'gpt-3.5-turbo',
                'messages': [{'role': 'user', 'content': 'Hello! Please respond briefly.'}],
                'stream': False,
                'max_tokens': 50
            }
        )
        
        print(f'状态码: {response.status_code}')
        print(f'Content-Type: {response.headers.get("content-type")}')
        
        if response.status_code == 200:
            result = response.json()
            print('✅ 非流式请求成功')
            print('📊 响应结构:')
            print(f'  - choices: {len(result.get("choices", []))}')
            print(f'  - usage: {result.get("usage")}')
            print(f'  - model: {result.get("model")}')
        else:
            print(f'❌ 状态码不是200: {response.status_code}')
            print(f'错误内容: {response.text[:200]}')
            
    except Exception as e:
        print(f'❌ 请求失败: {e}')
    
    print()
    print('=' * 60)
    
    # 测试3: 错误情况 - 缺少 targetHost
    print('测试3: 错误情况 - 缺少 targetHost')
    try:
        response = requests.post(
            'http://localhost:8000/proxy',  # 没有 targetHost 和 path
            headers={
                'Authorization': 'Bearer sk-my-secret-key-1',
                'Content-Type': 'application/json'
            },
            json={
                'model': 'gpt-3.5-turbo',
                'messages': [{'role': 'user', 'content': 'Hello!'}],
                'stream': True
            }
        )
        
        print(f'状态码: {response.status_code}')
        if response.status_code == 400:
            result = response.json()
            print('✅ 正确返回400错误')
            print(f'错误信息: {result.get("error")}')
        else:
            print(f'⚠️  状态码: {response.status_code}')
            print(f'内容: {response.text[:200]}')
            
    except Exception as e:
        print(f'❌ 请求失败: {e}')
    
    print()
    print('=' * 60)
    print('🎉 流式请求转发测试完成！')

if __name__ == '__main__':
    test_proxy_streaming()