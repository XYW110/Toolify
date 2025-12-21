# Docker Registry Debug Guide

This document explains how to debug and resolve common issues with the Toolify Docker image from GitHub Container Registry.

## Common Issues

### "manifest unknown" Error

This error can occur for several reasons even when the image exists in the registry:

1. **Architecture mismatch** - The image was built for different architectures than your system
2. **Registry synchronization delay** - Temporary delay in GitHub Container Registry
3. **Docker cache issues** - Local Docker cache contains outdated information
4. **Authentication issues** - Missing or incorrect authentication to GitHub Container Registry

## Debug Steps

### 1. Check Available Tags
First, verify that the image and tags exist:
- Visit: https://github.com/XYW110/Toolify/pkgs/container/toolify
- Check which tags are available (latest, main, commit hashes)

### 2. Try Specific Tags
Instead of using `latest`, try using specific available tags:
```bash
# Try the main branch tag
docker pull ghcr.io/xyw110/toolify:main

# Try the latest commit hash tag
docker pull ghcr.io/xyw110/toolify:de1e92d
```

### 3. Check Architecture Compatibility
```bash
# Check your system architecture
uname -m

# Try pulling with specific platform
docker pull --platform linux/amd64 ghcr.io/xyw110/toolify:latest
# or
docker pull --platform linux/arm64 ghcr.io/xyw110/toolify:latest
```

### 4. Clear Docker Cache
```bash
# Clean up unused Docker data
docker system prune -a

# Remove specific image if cached incorrectly
docker rmi ghcr.io/xyw110/toolify:latest

# Try pulling again
docker pull ghcr.io/xyw110/toolify:latest
```

### 5. Check Manifest
```bash
# Inspect the image manifest to see available platforms
docker manifest inspect ghcr.io/xyw110/toolify:latest
```

### 6. Authentication
Make sure you're properly authenticated:
```bash
# Login to GitHub Container Registry
docker login ghcr.io

# Or use a personal access token
echo $GITHUB_TOKEN | docker login ghcr.io -u XYW110 --password-stdin
```

## Multi-Platform Builds

The GitHub Actions workflow builds for multiple platforms (linux/amd64, linux/arm64). If you're experiencing issues, it might be due to:

1. **QEMU emulation** - Your system may not have proper QEMU emulation for different architectures
2. **Manifest list issues** - The multi-arch manifest may not be properly generated

## Alternative Solutions

### 1. Use Local Build
If registry issues persist, build locally:
```bash
docker build -t ghcr.io/xyw110/toolify:latest .
```

### 2. Use Docker Compose with Local Build
Use the fallback configuration we created:
```bash
docker-compose -f docker-compose.fallback.yml up -d
```

### 3. Force Specific Architecture
If you know your system architecture:
```bash
# For AMD64/x86_64 systems
docker pull --platform linux/amd64 ghcr.io/xyw110/toolify:latest

# For ARM64 systems (like Apple Silicon Macs)
docker pull --platform linux/arm64 ghcr.io/xyw110/toolify:latest
```

## Verification

After successfully pulling the image, verify it works:
```bash
# Run a quick test
docker run --rm -it ghcr.io/xyw110/toolify:latest python -c "import sys; print(f'Python {sys.version}')"

# Or test the application (requires config file)
docker run --rm -p 8000:8000 -v $(pwd)/config.yaml:/app/config.yaml ghcr.io/xyw110/toolify:latest
```

## GitHub Actions Status

Check the GitHub Actions status to ensure the image was properly built:
- Visit: https://github.com/XYW110/Toolify/actions
- Look for successful "Publish Docker Image" workflow runs
- The latest run should have pushed the `latest` tag

## If All Else Fails

1. Wait a few minutes for potential registry synchronization
2. Try again from a different network or location
3. Use the local build approach as a reliable fallback
4. Contact repository maintainers if the issue persists

The Docker image should be available and working, as the GitHub Actions workflow has successfully built and pushed it. The issue is most likely related to local Docker configuration, architecture compatibility, or temporary registry issues.