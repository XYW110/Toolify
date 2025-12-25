# Toolify

[English](README.md) | [简体中文](README_zh.md)

**为任何大型语言模型赋予函数调用能力。**

Toolify 是一个中间件代理，旨在为那些本身不支持函数调用功能的大型语言模型，或未提供函数调用功能的 OpenAI 接口注入兼容 OpenAI 格式的函数调用能力。它作为您的应用程序和上游 LLM API 之间的中介，负责注入必要的提示词并从模型的响应中解析工具调用。

## 核心特性

- **通用函数调用**：为遵循 OpenAI API 格式但缺乏原生支持的 LLM 或接口启用函数调用。
- **多函数调用支持**：支持在单次响应中同时执行多个函数。
- **灵活的调用时机**：允许在模型输出的任意阶段启动函数调用。
- **兼容 `<think>` 标签**：无缝处理 `<think>` 标签，确保它们不会干扰工具解析。
- **流式响应支持**：全面支持流式响应，实时检测和解析函数调用。
- **多服务路由**：根据请求的模型名称，将请求路由到不同的上游服务。
- **客户端认证**：通过可配置的客户端 API 密钥保护中间件安全。
- **增强的上下文感知**：在返回工具执行结果时，会基于请求携带的对话历史补充该工具的名称与参数，一并提供给上游模型，以提升上下文理解能力。

## 工作原理

1. **拦截请求**：Toolify 拦截来自客户端的 `chat/completions` 请求，该请求包含所需的工具定义。
2. **注入提示词**：生成一个特定的系统提示词，指导 LLM 使用结构化的 XML 格式和唯一的触发信号来输出函数调用。
3. **代理到上游**：将修改后的请求发送到配置的上游 LLM 服务。
4. **解析响应**：Toolify 分析上游响应。如果检测到触发信号，它会解析 XML 结构以提取函数调用。
5. **格式化响应**：将解析出的工具调用转换为标准的 OpenAI `tool_calls` 格式，并将其发送回客户端。

## 安装与设置

您可以通过 Docker Compose 或使用 Python 直接运行 Toolify。

### 选项 1: 使用 Docker Compose

这是推荐的简易部署方式。

#### 前提条件

- 已安装 Docker 和 Docker Compose。

#### 步骤

1. **克隆仓库：**

   ```bash
   git clone https://github.com/funnycups/toolify.git
   cd toolify
   ```

2. **配置应用程序：**

   复制示例配置文件并进行编辑：

   ```bash
   cp config.example.yaml config.yaml
   ```

   编辑 `config.yaml`。`docker-compose.yml` 文件已配置为将此文件挂载到容器中。

3. **启动服务：**

   ```bash
   docker-compose up -d --build
   ```

   这将构建 Docker 镜像并以后台模式启动 Toolify 服务，可通过 `http://localhost:8000` 访问。

### 选项 2: 使用 Python

#### 前提条件

- Python 3.8+

#### 步骤

1. **克隆仓库：**

   ```bash
   git clone https://github.com/funnycups/toolify.git
   cd toolify
   ```

2. **安装依赖：**

   ```bash
   pip install -r requirements.txt
   ```

3. **配置应用程序：**

   复制示例配置文件并进行编辑：

   ```bash
   cp config.example.yaml config.yaml
   ```

   编辑 `config.yaml` 文件，设置您的上游服务、API 密钥以及允许的客户端密钥。

4. **运行服务器：**

   ```bash
   python main.py
   ```

## 配置 (`config.yaml`)

请参考 [`config.example.yaml`](config.example.yaml) 获取详细的配置选项说明。

- **`server`**：中间件的主机、端口和超时设置。
- **`upstream_services`**：上游 LLM 提供商列表。
  - 定义 `base_url`、`api_key`、支持的 `models`，并设置一个服务为 `is_default: true`。
- **`client_authentication`**：允许访问此中间件的客户端 `allowed_keys` 列表。
- **`features`**：切换日志记录、角色转换和 API 密钥处理等功能。
  - `key_passthrough`: 设置为 `true` 时，将直接把客户端提供的 API 密钥转发给上游服务，而不是使用 `upstream_services` 中配置的 `api_key`。
  - `model_passthrough`: 设置为 `true` 时，将所有请求直接转发到名为 'openai' 的上游服务，忽略任何基于模型的路由规则。
  - `prompt_template`: 自定义用于指导模型如何使用工具的系统提示词。

## 使用方法

Toolify 运行后，将您的客户端应用程序（例如使用 OpenAI SDK）的 `base_url` 配置为 Toolify 的地址。使用您配置的 `allowed_keys` 之一进行身份验证。

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",  # Toolify 终结点
    api_key="sk-my-secret-key-1"          # 您配置的客户端密钥
)

# 其余的 OpenAI API 调用保持不变，包括工具定义。
```

Toolify 负责处理标准 OpenAI 工具格式与不支持的 LLM 所需的基于提示词的方法之间的转换。

## 动态 AI 代理路由

Toolify 现在支持通过 `/proxy` 端点进行动态 AI 代理路由。此功能允许您通过查询参数指定目标主机和路径，动态地将请求路由到任何兼容 OpenAI 的 AI 服务。

### 功能特性

- **动态路由**: 通过指定 `targetHost` 查询参数，将请求路由到任何上游 AI 服务
- **完全兼容 OpenAI**: 接受与 OpenAI `chat/completions` 端点相同的 POST 请求格式，包括 `messages`、`tools`、`stream` 等字段
- **函数调用支持**: 像原有的 `/v1/chat/completions` 路由一样，对请求进行函数调用注入的处理
- **API 密钥处理**: 与原有路由保持一致的 API 密钥查找逻辑，即根据请求体中的 `model` 字段去 `config.yaml` 中查找

### 使用方法

要使用动态 AI 代理路由功能，请向 `/proxy` 端点发送 POST 请求，并包含以下参数：

- **查询参数**: `targetHost` - 目标上游 AI 服务器的域名
- **查询参数**: `path` - 目标服务器上的 API 路径（例如 `/v1/chat/completions`）
- **请求体**: 标准的 OpenAI `chat/completions` 请求格式

示例 curl 请求：

```bash
curl -X POST "http://localhost:8000/proxy?targetHost=api.openai.com&path=/v1/chat/completions" \
  -H "Authorization: Bearer sk-my-secret-key-1" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "stream": false
  }'
```

### Python 示例

```python
import requests

response = requests.post(
    'http://localhost:8000/proxy?targetHost=api.openai.com&path=/v1/chat/completions',
    headers={'Authorization': 'Bearer sk-my-secret-key-1'},
    json={
        'model': 'gpt-3.5-turbo',
        'messages': [{'role': 'user', 'content': 'Hello!'}],
        'stream': False
    }
)

if response.status_code == 200:
    result = response.json()
    print(result)
else:
    print(f"错误: {response.status_code} - {response.text}")
```

## 许可证

本项目采用 GPL-3.0-or-later 许可证。

## Docker 部署

### 使用 GitHub Container Registry 的预构建镜像

您可以拉取并运行从 GitHub Container Registry 获取的预构建 Toolify 镜像：

```bash
# 拉取最新镜像
docker pull ghcr.io/xyw110/toolify:latest

# 运行容器
docker run -p 8000:8000 -v $(pwd)/config.yaml:/app/config.yaml ghcr.io/xyw110/toolify:latest
```

### 使用 Docker Compose 与 GitHub Container Registry

您可以更新 `docker-compose.yml` 文件以使用来自 GitHub Container Registry 的镜像：

```yaml
version: "3.8"

services:
  toolify:
    image: ghcr.io/xyw110/toolify:latest # 使用您实际的用户名
    container_name: toolify
    ports:
      - "8000:8000"
    volumes:
      - ./config.yaml:/app/config.yaml
    restart: unless-stopped
```

#### 完整的 Docker Compose 设置指南

1. **准备配置文件：**

   ```bash
   # 复制示例配置
   cp config.example.yaml config.yaml
   # 使用您的设置编辑配置文件
   # 确保设置您的 API 密钥和上游服务
   ```

2. **创建或更新 `docker-compose.yml` 文件：**

   ```yaml
   version: "3.8"

   services:
     toolify:
       image: ghcr.io/xyw110/toolify:latest
       container_name: toolify
       ports:
         - "8000:8000"
       volumes:
         - ./config.yaml:/app/config.yaml
         # 可选：添加日志的命名卷
         # - toolify_logs:/app/logs
       environment:
         - PYTHONUNBUFFERED=1
       restart: unless-stopped
       # 可选：添加健康检查
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost:8000/"]
         interval: 30s
         timeout: 10s
         retries: 3
         start_period: 40s
   # 可选：定义命名卷
   # volumes:
   #   toolify_logs:
   ```

3. **启动服务：**

   ```bash
   # 后台启动
   docker-compose up -d

   # 查看日志
   docker-compose logs -f
   ```

4. **验证服务是否正在运行：**

   ```bash
   # 检查容器是否正在运行
   docker-compose ps

   # 测试 API
   curl http://localhost:8000/
   ```

5. **管理服务：**

   ```bash
   # 停止服务
   docker-compose down

   # 更新到最新镜像
   docker-compose pull && docker-compose up -d

   # 查看日志
   docker-compose logs

   # 重启服务
   docker-compose restart
   ```

### 自动化发布与 GitHub Actions

此项目包含多个 GitHub Actions 工作流，当您推送到 `main` 分支或创建标签时，它们会自动构建和发布 Docker 镜像。要启用此功能：

1. 确保仓库中存在工作流文件：
   - `.github/workflows/docker-publish.yml` - 原始多架构工作流
   - `.github/workflows/docker-publish-simple.yml` - 单架构工作流（推荐用于更好的兼容性）
   - `.github/workflows/docker-hub-publish.yml` - Docker Hub 发布工作流
2. 工作流将在推送到 `main` 或创建标签时自动运行
3. 镜像将发布到 `ghcr.io/your-username/toolify` 或 Docker Hub

#### 故障排除：如果 GitHub Container Registry 镜像不可用

如果在 24 小时后您仍然遇到 "manifest unknown" 错误，这可能表明 GitHub Actions 未成功运行。在这种情况下，您可以手动构建并推送镜像：

1. **确保已登录到 GitHub Container Registry：**

   ```bash
   docker login ghcr.io
   # 使用具有 'write:packages' 作用域的 GitHub 个人访问令牌
   ```

2. **手动构建并推送镜像：**

   ```bash
   # 构建带有适当标签的镜像
   docker build -t ghcr.io/xyw110/toolify:latest -t ghcr.io/xyw110/toolify:$(git describe --tags --always) .

   # 推送镜像
   docker push ghcr.io/xyw110/toolify:latest
   docker push ghcr.io/xyw110/toolify:$(git describe --tags --always)
   ```

3. **替代方案：使用手动构建脚本（如果可用）：**

   ```bash
   # 在 Unix 系统上
   chmod +x scripts/build-and-push-manual.sh
   ./scripts/build-and-push-manual.sh

   # 在 Windows 上，您可以手动运行构建命令：
   docker build -t ghcr.io/xyw110/toolify:latest .
   docker push ghcr.io/xyw110/toolify:latest
   ```
