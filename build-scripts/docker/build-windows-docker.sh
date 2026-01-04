#!/bin/bash
# BitMinti Windows Build (Dockerized)
# Builds Windows binaries (CLI + GUI) inside a Docker container
# Usage: ./build-scripts/build-windows-docker.sh

set -e

# Resolve locations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Add Docker to PATH for this script execution
export PATH=$PATH:/Applications/Docker.app/Contents/Resources/bin

echo "========================================"
echo "BitMinti Windows GUI Build (Docker)"
echo "========================================"
echo "Project Root: $PROJECT_ROOT"
echo ""

# 1. Create Dockerfile on the fly
cat > "$PROJECT_ROOT/Dockerfile.windows" << 'EOF'
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for cross-compilation
RUN apt-get update && apt-get install -y \
    build-essential \
    libtool autotools-dev automake pkg-config bsdmainutils curl git \
    g++-mingw-w64-x86-64 \
    cmake \
    zip \
    imagemagick \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /btc5

# Command to run build
CMD ["bash", "-c", "./build-scripts/windows/build-windows-gui.sh"]
EOF

echo "Step 1: Building Docker image..."
echo "This creates a clean environment with MinGW-w64..."
docker build -t bitminti-builder-windows -f "$PROJECT_ROOT/Dockerfile.windows" "$PROJECT_ROOT"

echo ""
echo "Step 2: Running Build inside Docker..."
echo "This will mount your source code and build 'bitminti-qt.exe'"
echo "Warning: This can take 30-90 minutes (building Qt from source)!"
echo ""

docker run --rm \
    -v "$PROJECT_ROOT:/btc5" \
    -w /btc5 \
    bitminti-builder-windows

echo ""
echo "========================================"
echo "✅ Docker Build Complete!"
echo "========================================"
echo "Look for 'bitminti-windows-gui-x64.zip' in your project root."

# Clean up Dockerfile
rm -f "$PROJECT_ROOT/Dockerfile.windows"
