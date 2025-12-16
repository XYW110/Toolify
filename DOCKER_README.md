# Toolify Docker Guide

## Overview

Toolify is a middleware proxy designed to inject OpenAI-compatible function calling capabilities into Large Language Models that do not natively support it. This document provides detailed information about running Toolify with Docker.

## Prerequisites

- Docker version 18.09 or higher
- Docker Compose (optional, for multi-container setups)
- An existing `config.yaml` file with your upstream service configuration

## Quick Start

### Using Docker Run

```bash
# Pull the latest image from GitHub Container Registry
docker pull ghcr.io/funnycups/toolify:latest

# Run Toolify with your configuration file
docker run -d -p 8000:8000 -v $(pwd)/config.yaml:/app/config.yaml --name toolify ghcr.io/funnycups/toolify:latest
```

### Using Docker Compose

```yaml
version: '3.8'

services:
  toolify:
    image: ghcr.io/funnycups/toolify:latest
    container_name: toolify
    ports:
      - "8000:8000"
    volumes:
      - ./config.yaml:/app/config.yaml
    restart: unless-stopped
```

Save the above content as `docker-compose.yml` and run:

```bash
docker-compose up -d
```

## Configuration

### Config File

Toolify requires a `config.yaml` file to specify upstream services, API keys, and other settings. You can use the example configuration file as a starting point:

```bash
# Copy the example configuration
cp config.example.yaml config.yaml
# Edit the file with your specific settings
```

Key configuration sections:

- `server`: Port and host settings
- `upstream_services`: List of upstream LLM services with API keys
- `client_authentication`: API keys for securing Toolify
- `features`: Various feature toggles

### Environment Variables

Currently, Toolify doesn't use environment variables directly. All configuration is done through the `config.yaml` file. However, you can mount different config files based on your environment:

```bash
# For production
docker run -d -p 8000:8000 -v $(pwd)/config.prod.yaml:/app/config.yaml --name toolify ghcr.io/funnycups/toolify:latest

# For development
docker run -d -p 8000:8000 -v $(pwd)/config.dev.yaml:/app/config.yaml --name toolify ghcr.io/funnycups/toolify:latest
```

## Docker Image Tags

- `latest`: The most recent stable version
- `vX.Y.Z`: Specific version tags (e.g., `v1.0.0`)
- Branch-specific tags: Images built from specific branches

## Docker Compose Advanced Setup

For more complex setups, you can use this advanced Docker Compose configuration:

```yaml
version: '3.8'

services:
  toolify:
    image: ghcr.io/funnycups/toolify:latest
    container_name: toolify
    ports:
      - "8000:8000"
    volumes:
      - ./config.yaml:/app/config.yaml
      - toolify-logs:/app/logs  # Persistent logs
    environment:
      - PYTHONUNBUFFERED=1
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  toolify-logs:
```

## Building the Image Locally

If you want to build the Docker image from source:

```bash
# Build the image
docker build -t toolify:local .

# Run with the locally built image
docker run -d -p 8000:8000 -v $(pwd)/config.yaml:/app/config.yaml --name toolify toolify:local
```

## Multi-architecture Support

The published Docker images support multiple architectures:

- `linux/amd64` (x86_64)
- `linux/arm64` (ARM 64-bit)

This enables Toolify to run on various platforms, including Raspberry Pi and other ARM-based systems.

## Security Considerations

1. **API Keys**: Never commit your `config.yaml` file with real API keys to version control.
2. **Network Access**: By default, the container only exposes port 8000. Limit network access as needed.
3. **Volume Mounts**: Only mount necessary volumes to minimize attack surface.
4. **Image Verification**: Always use verified images from official sources.

## Troubleshooting

### Container won't start

- Check the Docker logs: `docker logs toolify`
- Verify your config.yaml is properly formatted
- Ensure the config file is accessible and has correct permissions

### Port already in use

- Change the host port mapping: `-p 8001:8000`
- Stop other services using port 8000

### Configuration issues

- Test your config.yaml with a YAML validator
- Ensure all required fields are present in the configuration

### Network connectivity issues

- Check if your upstream services are accessible from the container
- Verify API keys and URLs in your configuration

## Updating Toolify

### Using Docker (latest version)

```bash
# Pull the latest image
docker pull ghcr.io/funnycups/toolify:latest

# Stop the current container
docker stop toolify

# Remove the old container
docker rm toolify

# Run the new version
docker run -d -p 8000:8000 -v $(pwd)/config.yaml:/app/config.yaml --name toolify ghcr.io/funnycups/toolify:latest
```

### Using Docker Compose

```bash
# Pull the latest image
docker-compose pull

# Recreate the container with the new image
docker-compose up -d
```

## Contributing

If you'd like to contribute to Toolify's Docker support:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with Docker
5. Submit a pull request

## License

This project is licensed under the GPL-3.0-or-later license. See the [LICENSE](LICENSE) file for details.