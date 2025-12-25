# Toolify

[English](README.md) | [简体中文](README_zh.md)

**Empower any LLM with function calling capabilities.**

Toolify is a middleware proxy designed to inject OpenAI-compatible function calling capabilities into Large Language Models that do not natively support it, or into OpenAI API interfaces that do not provide this functionality. It acts as an intermediary between your application and the upstream LLM API, injecting necessary prompts and parsing tool calls from the model's response.

## Key Features

- **Universal Function Calling**: Enables function calling for LLMs or APIs that adhere to the OpenAI format but lack native support.
- **Multiple Function Calls**: Supports executing multiple functions simultaneously in a single response.
- **Flexible Initiation**: Allows function calls to be initiated at any stage of the model's output.
- **Think Tag Compatibility**: Seamlessly handles `<think>` tags, ensuring they don't interfere with tool parsing.
- **Streaming Support**: Fully supports streaming responses, detecting and parsing function calls on the fly.
- **Multi-Service Routing**: Routes requests to different upstream services based on the requested model name.
- **Client Authentication**: Secures the middleware with configurable client API keys.
- **Enhanced Context Awareness**: When tool results are provided (role=`tool`), Toolify includes the tool name and arguments (derived from the request's conversation history) alongside the execution results for better upstream context.

## How It Works

1. **Intercept Request**: Toolify intercepts the `chat/completions` request from the client, which includes the desired tools.
2. **Inject Prompt**: It generates a specific system prompt instructing the LLM how to output function calls using a structured XML format and a unique trigger signal.
3. **Proxy to Upstream**: The modified request is sent to the configured upstream LLM service.
4. **Parse Response**: Toolify analyzes the upstream response. If the trigger signal is detected, it parses the XML structure to extract the function calls.
5. **Format Response**: It transforms the parsed tool calls into the standard OpenAI `tool_calls` format and sends it back to the client.

## Installation and Setup

You can run Toolify using Docker Compose or Python directly.

### Option 1: Using Docker Compose

This is the recommended way for easy deployment.

#### Prerequisites

- Docker and Docker Compose installed.

#### Steps

1. **Clone the repository:**

   ```bash
   git clone https://github.com/funnycups/toolify.git
   cd toolify
   ```

2. **Configure the application:**

   Copy the example configuration file and edit it:

   ```bash
   cp config.example.yaml config.yaml
   ```

   Edit `config.yaml`. The `docker-compose.yml` file is configured to mount this file into the container.

3. **Start the service:**

   ```bash
   docker-compose up -d --build
   ```

   This will build the Docker image and start the Toolify service in detached mode, accessible at `http://localhost:8000`.

### Option 2: Using Python

#### Prerequisites

- Python 3.8+

#### Steps

1. **Clone the repository:**

   ```bash
   git clone https://github.com/funnycups/toolify.git
   cd toolify
   ```

2. **Install dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

3. **Configure the application:**

   Copy the example configuration file and edit it:

   ```bash
   cp config.example.yaml config.yaml
   ```

   Edit `config.yaml` to set up your upstream services, API keys, and allowed client keys.

4. **Run the server:**

   ```bash
   python main.py
   ```

## Configuration (`config.yaml`)

Refer to [`config.example.yaml`](config.example.yaml) for detailed configuration options.

- **`server`**: Middleware host, port, and timeout settings.
- **`upstream_services`**: List of upstream LLM providers (e.g., Groq, OpenAI, Anthropic).
  - Define `base_url`, `api_key`, supported `models`, and set one service as `is_default: true`.
- **`client_authentication`**: List of `allowed_keys` for clients accessing this middleware.
- **`features`**: Toggle features like logging, role conversion, and API key handling.
  - `key_passthrough`: Set to `true` to directly forward the client-provided API key to the upstream service, bypassing the configured `api_key` in `upstream_services`.
  - `model_passthrough`: Set to `true` to forward all requests directly to the upstream service named 'openai', ignoring any model-based routing rules.
  - `prompt_template`: Customize the system prompt used to instruct the model on how to use tools.

## Usage

Once Toolify is running, configure your client application (e.g., using the OpenAI SDK) to use Toolify's address as the `base_url`. Use one of the configured `allowed_keys` for authentication.

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",  # Toolify endpoint
    api_key="sk-my-secret-key-1"          # Your configured client key
)

# The rest of your OpenAI API calls remain the same, including tool definitions.
```

Toolify handles the translation between the standard OpenAI tool format and the prompt-based method required by unsupported LLMs.

## Dynamic AI Proxy Routing

Toolify now supports dynamic AI proxy routing through the `/proxy` endpoint. This feature allows you to route requests to any OpenAI-compatible AI service dynamically by specifying the target host and path via query parameters.

### Features

- **Dynamic Routing**: Route requests to any upstream AI service by specifying the `targetHost` query parameter.
- **Full OpenAI Compatibility**: Accepts the same POST request format as OpenAI's `chat/completions` endpoint, including `messages`, `tools`, `stream`, etc.
- **Function Calling Support**: Processes requests with function calling injection, just like the original `/v1/chat/completions` route.
- **API Key Handling**: Uses the same API key lookup logic as the original route, finding keys based on the `model` field in the request body from `config.yaml`.

### Usage

To use the dynamic AI proxy routing feature, send a POST request to the `/proxy` endpoint with the following parameters:

- **Query Parameter**: `targetHost` - The domain of the target upstream AI server
- **Query Parameter**: `path` - The API path on the target server (e.g., `/v1/chat/completions`)
- **Request Body**: Standard OpenAI `chat/completions` request format

Example curl request:

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

### Example with Python

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
    print(f"Error: {response.status_code} - {response.text}")
```

## License

This project is licensed under the GPL-3.0-or-later license.

## Docker Deployment

### Using Pre-built Images from GitHub Container Registry

You can pull and run the pre-built Toolify image from GitHub Container Registry:

```bash
# Pull the latest image
docker pull ghcr.io/funnycups/toolify:latest

# Run the container
docker run -p 8000:8000 -v $(pwd)/config.yaml:/app/config.yaml ghcr.io/funnycups/toolify:latest
```

### Building and Publishing to GitHub Container Registry

To build and publish your own version of Toolify to GitHub Container Registry:

1. **Make sure you have Docker installed and are logged in to GitHub:**

   ```bash
   docker login ghcr.io
   ```

2. **Run the publish script to build the Docker image:**

   ```bash
   # Make the script executable
   chmod +x scripts/publish-docker.sh

   # Run the script
   ./scripts/publish-docker.sh
   ```

3. **Push the image to GitHub Container Registry:**

   ```bash
   # Push the versioned tag
   docker push ghcr.io/your-username/toolify:version-tag

   # Push the latest tag
   docker push ghcr.io/your-username/toolify:latest
   ```

### Using Docker Compose with GitHub Container Registry

You can update the `docker-compose.yml` file to use the image from GitHub Container Registry:

```yaml
version: "3.8"

services:
  toolify:
    image: ghcr.io/xyw110/toolify:latest # Using your published image
    container_name: toolify
    ports:
      - "8000:8000"
    volumes:
      - ./config.yaml:/app/config.yaml
    restart: unless-stopped
```

#### Complete Docker Compose Setup Guide

1. **Prepare your configuration file:**

   ```bash
   # Copy the example configuration
   cp config.example.yaml config.yaml
   # Edit the configuration file with your settings
   # Make sure to set your API keys and upstream services
   ```

2. **Create or update your `docker-compose.yml` file:**

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
         # Optional: Add a named volume for logs
         # - toolify_logs:/app/logs
       environment:
         - PYTHONUNBUFFERED=1
       restart: unless-stopped
       # Optional: Add health check
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost:8000/"]
         interval: 30s
         timeout: 10s
         retries: 3
         start_period: 40s
   # Optional: Define named volumes
   # volumes:
   #   toolify_logs:
   ```

3. **Start the service:**

   ```bash
   # Start in background
   docker-compose up -d

   # Check the logs
   docker-compose logs -f
   ```

4. **Verify the service is running:**

   ```bash
   # Check if the container is running
   docker-compose ps

   # Test the API
   curl http://localhost:8000/
   ```

5. **Manage the service:**

   ```bash
   # Stop the service
   docker-compose down

   # Update to the latest image
   docker-compose pull && docker-compose up -d

   # View logs
   docker-compose logs

   # Restart the service
   docker-compose restart
   ```

#### Environment-Specific Docker Compose

For different environments, you can create specific compose files:

**docker-compose.prod.yml** (Production):

```yaml
version: "3.8"

services:
  toolify:
    image: ghcr.io/xyw110/toolify:latest
    container_name: toolify-prod
    ports:
      - "8000:8000"
    volumes:
      - ./config.prod.yaml:/app/config.yaml
    restart: unless-stopped
    environment:
      - PYTHONUNBUFFERED=1
    # Add resource limits for production
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: "0.5"
        reservations:
          memory: 512M
          cpus: "0.25"
```

**docker-compose.dev.yml** (Development):

```yaml
version: "3.8"

services:
  toolify:
    image: ghcr.io/xyw110/toolify:latest
    container_name: toolify-dev
    ports:
      - "8000:8000"
    volumes:
      - ./config.dev.yaml:/app/config.yaml
      # Mount source code for development (optional)
      # - .:/app
    restart: unless-stopped
    environment:
      - PYTHONUNBUFFERED=1
    # Enable more verbose logging for development
    command:
      ["main:app", "--host", "0.0.0.0", "--port", "8000", "--log-level", "info"]
```

To use environment-specific files:

```bash
# For production
docker-compose -f docker-compose.prod.yml up -d

# For development
docker-compose -f docker-compose.dev.yml up -d
```

#### Docker Compose with Custom Network

For better container isolation, you can create a custom network:

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
    restart: unless-stopped
    networks:
      - toolify-network
    environment:
      - PYTHONUNBUFFERED=1

networks:
  toolify-network:
    driver: bridge
```

## Automated Publishing with GitHub Actions

This project includes GitHub Actions workflows that automatically build and publish Docker images when you push to the `main` branch or create a tag. To enable this:

1. Make sure the workflow files exist in your repository:
   - `.github/workflows/docker-publish.yml` - Original multi-arch workflow
   - `.github/workflows/docker-publish-simple.yml` - Single-arch workflow (recommended for better compatibility)
   - `.github/workflows/docker-hub-publish.yml` - Docker Hub publishing workflow
2. The workflows will automatically run on pushes to `main` or when creating tags
3. Images will be published to `ghcr.io/your-username/toolify` or Docker Hub

### Troubleshooting: If GitHub Container Registry Image is Not Available

If you encounter a "manifest unknown" error after 24+ hours, it may indicate that GitHub Actions did not run successfully. In this case, you can manually build and push the image:

1. **Ensure you're logged into GitHub Container Registry:**

   ```bash
   docker login ghcr.io
   # Use a GitHub Personal Access Token with 'write:packages' scope
   ```

2. **Build and push the image manually:**

   ```bash
   # Build the image with appropriate tags
   docker build -t ghcr.io/xyw110/toolify:latest -t ghcr.io/xyw110/toolify:$(git describe --tags --always) .

   # Push the image
   docker push ghcr.io/xyw110/toolify:latest
   docker push ghcr.io/xyw110/toolify:$(git describe --tags --always)
   ```

3. **Alternative: Use the manual build script (if available):**

   ```bash
   # On Unix systems
   chmod +x scripts/build-and-push-manual.sh
   ./scripts/build-and-push-manual.sh

   # On Windows, you can run the build commands manually:
   docker build -t ghcr.io/xyw110/toolify:latest .
   docker push ghcr.io/xyw110/toolify:latest
   ```

The workflow supports multi-platform builds (AMD64 and ARM64).
