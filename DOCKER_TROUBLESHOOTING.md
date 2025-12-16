# Docker Troubleshooting Guide

This document explains common issues you might encounter when using the Toolify Docker image and how to resolve them.

## Common Issues and Solutions

### 1. "manifest unknown" Error

**Problem**: When trying to pull or run the Docker image, you get an error like:
```
Error response from daemon: manifest for ghcr.io/xyw110/toolify:latest not found: manifest unknown
```

**Cause**: This means the Docker image has not yet been built and published to GitHub Container Registry. This can happen for several reasons:

1. **GitHub Actions is still running**: The automated build process may still be in progress.
2. **Build failed**: There might have been an issue during the Docker image build process.
3. **First-time build**: If this is the first time the image is being published, it may take a few minutes.

**Solutions**:

#### Option 1: Wait and Retry
The GitHub Actions workflow should automatically build and publish the image. Wait a few minutes and try again:
```bash
docker pull ghcr.io/xyw110/toolify:latest
```

#### Option 2: Check GitHub Actions Status
1. Go to your GitHub repository: https://github.com/XYW110/Toolify
2. Click on the "Actions" tab
3. Check if there's a workflow running or completed for the recent commit
4. If there are errors in the workflow, review and fix them

#### Option 3: Build Locally
If the GitHub Container Registry image is not available yet, you can build the image locally:

```bash
# Build the image locally
docker build -t ghcr.io/xyw110/toolify:latest .

# Then run with Docker Compose
docker-compose up -d
```

#### Option 4: Use Alternative Tag
If the `latest` tag is not available, try using a specific version tag if one exists:
```bash
# Check available tags on GitHub Container Registry
docker pull ghcr.io/xyw110/toolify:v1.0.0  # Replace with actual available tag
```

### 2. Version Attribute Warning

**Problem**: You see a warning like:
```
the attribute version is obsolete, it will be ignored, please remove it
```

**Cause**: The `version` attribute in `docker-compose.yml` is no longer required in modern Docker Compose versions.

**Solution**: The `docker-compose.yml` file has been updated to remove the obsolete version attribute. This warning should no longer appear.

### 3. Configuration File Issues

**Problem**: Toolify fails to start or shows configuration errors.

**Solution**:
1. Make sure you have a `config.yaml` file in the same directory as your `docker-compose.yml`
2. Copy `config.example.yaml` to `config.yaml` and edit with your settings:
   ```bash
   cp config.example.yaml config.yaml
   # Edit config.yaml with your upstream services and API keys
   ```

### 4. Port Already in Use

**Problem**: You get an error about port 8000 already being in use.

**Solution**: Change the port mapping in `docker-compose.yml`:
```yaml
services:
  toolify:
    # ... other config ...
    ports:
      - "8001:8000"  # Changed from 8000:8000 to 8001:8000
```

## Checking Image Availability

You can check if your image is available on GitHub Container Registry by:

1. Visiting: `https://github.com/XYW110/Toolify/pkgs/container/toolify`
2. Or using the GitHub CLI:
   ```bash
   gh package list -R https://github.com/XYW110/Toolify
   ```

## Verifying Successful Deployment

After starting the service with Docker Compose, verify it's working:

```bash
# Check if the container is running
docker-compose ps

# Check the logs
docker-compose logs

# Test the API
curl http://localhost:8000/

# Expected response should be a JSON with Toolify status information
```

## Alternative: Using Docker Run

If Docker Compose continues to have issues, you can run the container directly:

```bash
# Pull the image
docker pull ghcr.io/xyw110/toolify:latest

# Run the container
docker run -d \
  --name toolify \
  -p 8000:8000 \
  -v $(pwd)/config.yaml:/app/config.yaml \
  -e PYTHONUNBUFFERED=1 \
  ghcr.io/xyw110/toolify:latest
```

## Building and Pushing Manually

If you need to manually build and push the image:

```bash
# Build the image
docker build -t ghcr.io/xyw110/toolify:latest .

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Push the image
docker push ghcr.io/xyw110/toolify:latest
```

Remember to replace `USERNAME` with your GitHub username and set the `GITHUB_TOKEN` environment variable with a token that has package write permissions.