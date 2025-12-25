#!/bin/bash

# Script to publish Toolify Docker image to GitHub Container Registry and Docker Hub
# Author: Toolify Team

set -e  # Exit on any error

echo "🚀 Starting Toolify Docker image publish process..."
echo ""

# Get the current version or tag from git, or use a default
VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "latest")
if [ "$VERSION" = "latest" ]; then
    # If git describe fails, try to get a version from the current date
    VERSION=$(date +%Y%m%d-%H%M%S)
fi

# GitHub Container Registry format: ghcr.io/{username}/{repository}
# We'll need the GitHub username/repo info, so let's extract it from the git remote
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [[ $REMOTE_URL =~ github.com[:/](.+)/(.*)(\\.git)?$ ]]; then
    GH_OWNER=${BASH_REMATCH[1]}
    GH_REPO=${BASH_REMATCH[2]}
    # Remove .git suffix if present
    GH_REPO=${GH_REPO%.git}
else
    echo "⚠️  Could not determine GitHub repository from remote."
    read -p "GitHub Username: " GH_OWNER
    read -p "GitHub Repository Name: " GH_REPO
    if [ -z "$GH_OWNER" ] || [ -z "$GH_REPO" ]; then
        echo "❌ Owner and repository name are required."
        exit 1
    fi
fi

# Docker Hub format: docker.io/{username}/{repository}
read -p "Docker Hub Username: " DH_USERNAME
if [ -z "$DH_USERNAME" ]; then
    echo "❌ Docker Hub username is required."
    exit 1
fi

# Set image names
GH_REGISTRY_IMAGE="ghcr.io/$GH_OWNER/$GH_REPO:$VERSION"
GH_REGISTRY_LATEST="ghcr.io/$GH_OWNER/$GH_REPO:latest"
DH_REGISTRY_IMAGE="docker.io/$DH_USERNAME/$GH_REPO:$VERSION"
DH_REGISTRY_LATEST="docker.io/$DH_USERNAME/$GH_REPO:latest"

echo ""
echo "📦 Image details:"
echo "   - GitHub Container Registry: $GH_REGISTRY_IMAGE"
echo "   - Docker Hub: $DH_REGISTRY_IMAGE"
echo "   - Repository: $GH_OWNER/$GH_REPO"
echo "   - Docker Hub User: $DH_USERNAME"
echo "   - Version: $VERSION"
echo ""

# Check if the local image exists
if ! docker images | grep -q "toolify.*local"; then
    echo "⚠️  Local toolify:local image not found."
    echo "   Building local image first..."
    docker build -t toolify:local .
fi

echo ""
echo "🔐 You need to login to both registries before pushing images."
echo ""
echo "1️⃣  Login to GitHub Container Registry:"
echo "   docker login ghcr.io"
echo "   # Use a GitHub Personal Access Token with 'write:packages' scope"
echo ""
echo "2️⃣  Login to Docker Hub:"
echo "   docker login"
echo "   # Use your Docker Hub credentials"
echo ""
echo "After logging in, press Enter to continue..."
read -p ""

echo ""
echo "🔄 Tagging image for GitHub Container Registry..."
docker tag toolify:local $GH_REGISTRY_IMAGE
docker tag toolify:local $GH_REGISTRY_LATEST

echo "🔄 Tagging image for Docker Hub..."
docker tag toolify:local $DH_REGISTRY_IMAGE
docker tag toolify:local $DH_REGISTRY_LATEST

echo ""
echo "📤 Pushing image to GitHub Container Registry..."
docker push $GH_REGISTRY_IMAGE
docker push $GH_REGISTRY_LATEST

echo ""
echo "📤 Pushing image to Docker Hub..."
docker push $DH_REGISTRY_IMAGE
docker push $DH_REGISTRY_LATEST

echo ""
echo "✅ Docker images published successfully!"
echo ""
echo "📋 Published images:"
echo "   - GitHub Container Registry: $GH_REGISTRY_IMAGE"
echo "   - GitHub Container Registry: $GH_REGISTRY_LATEST"
echo "   - Docker Hub: $DH_REGISTRY_IMAGE"
echo "   - Docker Hub: $DH_REGISTRY_LATEST"
echo ""
echo "💡 Pro tip: You can now pull the images using:"
echo "   # From GitHub Container Registry"
echo "   docker pull $GH_REGISTRY_LATEST"
echo ""
echo "   # From Docker Hub"
echo "   docker pull $DH_REGISTRY_LATEST"
echo ""