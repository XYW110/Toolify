#!/bin/bash

# Script to test Docker image build and basic functionality

echo "🔍 Testing Docker image build and functionality..."

# Build the image with a test tag
echo "🔨 Building Docker image..."
docker build -t toolify:test .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

echo "✅ Docker build successful!"

# Test running the image with a simple check
echo "🧪 Testing Docker image run..."
# Run container in the background and check if it starts properly
docker run -d --name toolify-test -p 8001:8000 --env PYTHONUNBUFFERED=1 toolify:test

# Wait a few seconds for the server to start
sleep 10

# Check if container is running
if docker ps | grep toolify-test > /dev/null; then
    echo "✅ Container started successfully!"
    
    # Try to access the root endpoint
    if curl -f http://localhost:8001/ > /dev/null 2>&1; then
        echo "✅ Application responding correctly!"
    else
        echo "⚠️  Application not responding, but container is running."
    fi
else
    echo "❌ Container failed to start properly!"
    docker logs toolify-test
fi

# Clean up
echo "🧹 Cleaning up test containers..."
docker stop toolify-test > /dev/null 2>&1
docker rmi toolify:test > /dev/null 2>&1

echo "✅ Docker test completed!"