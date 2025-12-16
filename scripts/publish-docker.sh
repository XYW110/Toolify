#!/bin/bash

# Script to build and publish Toolify Docker image to GitHub Container Registry

set -e  # Exit on any error

echo "🚀 Starting Toolify Docker image build and publish process..."

# Check if we're in the correct directory
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile not found in current directory. Please run this script from the project root."
    exit 1
fi

# Get the current version or tag from git, or use a default
VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "latest")
if [ "$VERSION" = "latest" ]; then
    # If git describe fails, try to get a version from the current date
    VERSION=$(date +%Y%m%d-%H%M%S)
fi

# GitHub Container Registry format: ghcr.io/{username}/{repository}
# We'll need the GitHub username/repo info, so let's extract it from the git remote
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [[ $REMOTE_URL =~ github.com[:/](.+)/(.*)(\.git)?$ ]]; then
    OWNER=${BASH_REMATCH[1]}
    REPO=${BASH_REMATCH[2]}
    # Remove .git suffix if present
    REPO=${REPO%.git}
else
    echo "⚠️  Could not determine GitHub repository from remote. Using default names."
    echo "Please manually enter your GitHub username and repository name:"
    read -p "GitHub Username: " OWNER
    read -p "Repository Name: " REPO
    if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
        echo "❌ Owner and repository name are required."
        exit 1
    fi
fi

# Docker image names
IMAGE_NAME="toolify"
GITHUB_REGISTRY_IMAGE="ghcr.io/$OWNER/$REPO:$VERSION"
GITHUB_REGISTRY_LATEST="ghcr.io/$OWNER/$REPO:latest"
LOCAL_IMAGE="$IMAGE_NAME:$VERSION"

echo "📦 Building Docker image..."
echo "   - Local image: $LOCAL_IMAGE"
echo "   - GitHub Container Registry: $GITHUB_REGISTRY_IMAGE"
echo "   - Repository: $OWNER/$REPO"
echo "   - Version: $VERSION"

# Build the Docker image
docker build -t "$LOCAL_IMAGE" -t "$GITHUB_REGISTRY_IMAGE" -t "$GITHUB_REGISTRY_LATEST" .

echo "✅ Docker image built successfully!"

echo ""
echo "📋 Next steps to publish to GitHub Container Registry:"
echo ""
echo "1. Login to GitHub Container Registry:"
echo "   docker login ghcr.io"
echo ""
echo "2. Authenticate with your GitHub token that has 'write:packages' scope"
echo ""
echo "3. Run these commands to push the image:"
echo "   docker push $GITHUB_REGISTRY_IMAGE"
echo "   docker push $GITHUB_REGISTRY_LATEST"
echo ""
echo "   Or, if you want to push specific version only:"
echo "   docker push $GITHUB_REGISTRY_IMAGE"
echo ""
echo "4. Verify the image is pushed:"
echo "   docker images | grep ghcr.io/$OWNER/$REPO"
echo ""
echo "💡 Pro tip: You can also specify the image name with tag when running:"
echo "   docker run -p 8000:8000 -v \$(pwd)/config.yaml:/app/config.yaml ghcr.io/$OWNER/$REPO:$VERSION"
echo ""
echo "🎉 Docker image build completed successfully!"