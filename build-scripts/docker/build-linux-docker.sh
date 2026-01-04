#!/bin/bash
# BitMinti Linux Build (Dockerized)
# Builds portable Linux binaries (CLI + GUI)
# Usage: ./build-scripts/build-linux-docker.sh

set -e

# Resolve locations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Add Docker to PATH
export PATH=$PATH:/Applications/Docker.app/Contents/Resources/bin

echo "========================================"
echo "BitMinti Portable Linux Build (Docker)"
echo "========================================"
echo "Project Root: $PROJECT_ROOT"
echo ""

# 1. Create Dockerfile
cat > "$PROJECT_ROOT/Dockerfile.linux" << 'EOF'
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for Linux build (with Qt support)
RUN apt-get update && apt-get install -y \
    build-essential \
    libtool autotools-dev automake pkg-config bsdmainutils curl git \
    cmake \
    python3 \
    bison \
    zip \
    imagemagick \
    libdbus-1-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /btc5

# Command to run build
CMD ["bash", "-c", "./build-scripts/build-linux-internal.sh"]
EOF

# 2. Create Internal Build Script (runs inside Docker)
cat > "$PROJECT_ROOT/build-scripts/build-linux-internal.sh" << 'EOF'
#!/bin/bash
set -e
echo "--- Starting Internal Build ---"

# Build Dependencies (Portable Linux)
cd depends
make HOST=x86_64-pc-linux-gnu -j$(nproc)
cd ..

# Configure
rm -rf build-linux-docker
mkdir -p build-linux-docker
cmake -B build-linux-docker \
    -DCMAKE_TOOLCHAIN_FILE="${PWD}/depends/x86_64-pc-linux-gnu/toolchain.cmake" \
    -DBUILD_GUI=ON \
    -DBUILD_TESTS=OFF \
    -DBUILD_BENCH=OFF

# Build
cmake --build build-linux-docker --target bitmintid bitminti-cli bitcoin-qt -j$(nproc)

# Package
echo "Grouping files..."
RELEASE_DIR="bitminti-linux-x64"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

cp build-linux-docker/src/bitmintid "$RELEASE_DIR/"
cp build-linux-docker/src/bitminti-cli "$RELEASE_DIR/"
cp build-linux-docker/src/qt/bitcoin-qt "$RELEASE_DIR/bitminti-qt"
cp dist/mine-linux.sh "$RELEASE_DIR/"
cp ONE_CLICK_MINING.md "$RELEASE_DIR/"
cp README.md "$RELEASE_DIR/"

# Create launch script for GUI
cat > "$RELEASE_DIR/start-gui.sh" << 'GUIEOF'
#!/bin/bash
./bitminti-qt
GUIEOF
chmod +x "$RELEASE_DIR/start-gui.sh"

tar -czf bitminti-linux-x64.tar.gz "$RELEASE_DIR"

echo "--- Build Complete inside Docker ---"
EOF

chmod +x "$PROJECT_ROOT/build-scripts/build-linux-internal.sh"

echo "Step 1: Building Docker image..."
docker build -t bitminti-builder-linux -f "$PROJECT_ROOT/Dockerfile.linux" "$PROJECT_ROOT"

echo ""
echo "Step 2: Running Build inside Docker..."
echo "This will create 'bitminti-linux-x64.tar.gz'"
echo ""

docker run --rm \
    -v "$PROJECT_ROOT:/btc5" \
    -w /btc5 \
    bitminti-builder-linux

echo ""
echo "========================================"
echo "✅ Linux Docker Build Complete!"
echo "========================================"
echo "Output: bitminti-linux-x64.tar.gz"

# Cleanup
rm -f "$PROJECT_ROOT/Dockerfile.linux"
rm -f "$PROJECT_ROOT/build-scripts/build-linux-internal.sh"
