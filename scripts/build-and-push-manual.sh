#!/bin/bash

# Script to manually build and push Toolify Docker image to GitHub Container Registry
# Use this when GitHub Actions fails or you need immediate access

set -e  # Exit on any error

echo "🚀 Manually building and pushing Toolify Docker image to GitHub Container Registry..."
echo ""

# Get repository info
if [[ $(git remote get-url origin 2>/dev/null) =~ github.com[:/](.+)/(.*)(\.git)?$ ]]; then
    OWNER=${BASH_REMATCH[1]}
    REPO=${BASH_REMATCH[2]%.git}
else
    echo "❌ Could not determine GitHub repository from remote."
    read -p "Enter your GitHub username: " OWNER
    read -p "Enter your repository name: " REPO
fi

# Check if logged into GitHub Container Registry
echo "🔍 Checking Docker registry login status..."
if ! docker info | grep -q "ghcr.io"; then
    echo "📦 You need to log in to GitHub Container Registry first:"
    echo "   docker login ghcr.io"
    echo ""
    echo "💡 Make sure to use a GitHub Personal Access Token with 'write:packages' scope"
    exit 1
fi

# Set image names
IMAGE_NAME="ghcr.io/$OWNER/$REPO"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
VERSION=$(git describe --tags --always 2>/dev/null || echo "$TIMESTAMP")

# Build and tag the images
echo "📦 Building Docker image..."
echo "   - Image: $IMAGE_NAME"
echo "   - Tags: $VERSION, latest"
echo ""

docker build -t "$IMAGE_NAME:$VERSION" -t "$IMAGE_NAME:latest" .

echo ""
echo "✅ Docker image built successfully!"
echo ""

# Push the images
echo "📤 Pushing Docker images to GitHub Container Registry..."
docker push "$IMAGE_NAME:$VERSION"
docker push "$IMAGE_NAME:latest"

echo ""
echo "🎉 Docker images pushed successfully!"
echo ""
echo "✅ You can now use the image with:"
echo "   docker pull $IMAGE_NAME:latest"
echo "   or with docker-compose using the updated docker-compose.yml"
echo ""
echo "💡 If using docker-compose, make sure you have:"
echo "   1. A config.yaml file in the same directory"
echo "   2. Run: docker-compose up -d"
echo ""