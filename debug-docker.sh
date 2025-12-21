#!/bin/bash

# Debug script to diagnose Docker/Registry issues

echo "🔍 Debugging Docker Registry Issues for Toolify"

echo ""
echo "1. Checking Docker version..."
docker --version

echo ""
echo "2. Checking Docker info..."
docker info | head -20

echo ""
echo "3. Checking available architectures..."
docker run --rm --privileged multiarch/qemu-user-static --list

echo ""
echo "4. Attempting to pull specific tag (de1e92d) instead of latest..."
docker pull ghcr.io/xyw110/toolify:de1e92d

if [ $? -eq 0 ]; then
    echo "✅ Specific tag pull successful"
else
    echo "❌ Specific tag pull failed"
fi

echo ""
echo "5. Attempting to pull main tag..."
docker pull ghcr.io/xyw110/toolify:main

if [ $? -eq 0 ]; then
    echo "✅ Main tag pull successful"
else
    echo "❌ Main tag pull failed"
fi

echo ""
echo "6. Checking if image exists locally..."
docker images | grep ghcr.io/xyw110/toolify

echo ""
echo "7. Testing with different platform (if needed)..."
echo "   To test a specific platform, use:"
echo "   docker pull --platform linux/amd64 ghcr.io/xyw110/toolify:latest"

echo ""
echo "8. If still failing, try manual authentication:"
echo "   echo \$GITHUB_TOKEN | docker login ghcr.io -u XYW110 --password-stdin"

echo ""
echo "Debug completed!"