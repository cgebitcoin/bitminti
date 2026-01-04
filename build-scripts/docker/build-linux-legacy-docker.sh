#!/bin/bash
# BitMinti Linux LEGACY Build (Dockerized)
# Builds Linux binaries (CLI + GUI) with Berkeley DB support (Legacy Wallets)
# Usage: ./build-scripts/build-linux-legacy-docker.sh

set -e

# Resolve locations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Add Docker to PATH
export PATH=$PATH:/Applications/Docker.app/Contents/Resources/bin

echo "========================================"
echo "BitMinti Linux LEGACY Build (Docker)"
echo "Enabling Berkeley DB (BDB) for legacy wallet support"
echo "========================================"
echo "Project Root: $PROJECT_ROOT"
echo ""

# 1. Create Dockerfile (Legacy needs BDB libs)
cat > "$PROJECT_ROOT/Dockerfile.legacy_build" << 'EOF'
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
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

# Command
CMD ["bash", "-c", "./build-scripts/build-linux-legacy-internal.sh"]
EOF

# 2. Create Internal Build Script
cat > "$PROJECT_ROOT/build-scripts/build-linux-legacy-internal.sh" << 'EOF'
#!/bin/bash
set -e
echo "--- Starting Legacy Build (with BDB) ---"

# Build Dependencies (Portable Linux + BDB)
cd depends
# NO_QT=0 (default) so we build Qt
make HOST=x86_64-pc-linux-gnu -j$(nproc)
cd ..

# Configure
rm -rf build-linux-legacy-docker
mkdir -p build-linux-legacy-docker

# Force BDB ON
cmake -B build-linux-legacy-docker \
    -DCMAKE_TOOLCHAIN_FILE="${PWD}/depends/x86_64-pc-linux-gnu/toolchain.cmake" \
    -DBUILD_GUI=ON \
    -DBUILD_TESTS=OFF \
    -DBUILD_BENCH=OFF \
    -DWITH_BDB=ON \
    -DWITH_SQLITE=ON

# Build
cmake --build build-linux-legacy-docker --target bitmintid bitminti-cli bitcoin-qt -j$(nproc)

# Package
echo "Grouping files..."
RELEASE_DIR="bitminti-linux-legacy-x64"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

cp build-linux-legacy-docker/src/bitmintid "$RELEASE_DIR/"
cp build-linux-legacy-docker/src/bitminti-cli "$RELEASE_DIR/"
cp build-linux-legacy-docker/src/qt/bitcoin-qt "$RELEASE_DIR/bitminti-qt"
cp dist/mine-linux.sh "$RELEASE_DIR/"
cp ONE_CLICK_MINING.md "$RELEASE_DIR/"
cp README.md "$RELEASE_DIR/"

cat > "$RELEASE_DIR/start-gui.sh" << 'GUIEOF'
#!/bin/bash
./bitminti-qt
GUIEOF
chmod +x "$RELEASE_DIR/start-gui.sh"

tar -czf bitminti-linux-legacy-x64.tar.gz "$RELEASE_DIR"

echo "--- Legacy Build Complete inside Docker ---"
EOF

chmod +x "$PROJECT_ROOT/build-scripts/build-linux-legacy-internal.sh"

echo "Step 1: Building Docker image..."
docker build -t bitminti-builder-legacy -f "$PROJECT_ROOT/Dockerfile.legacy_build" "$PROJECT_ROOT"

echo ""
echo "Step 2: Running Build inside Docker..."
docker run --rm \
    -v "$PROJECT_ROOT:/btc5" \
    -w /btc5 \
    bitminti-builder-legacy

echo ""
echo "========================================"
echo "✅ Linux Legacy Build Complete!"
echo "========================================"
echo "Output: bitminti-linux-legacy-x64.tar.gz"

# Cleanup
rm -f "$PROJECT_ROOT/Dockerfile.legacy_build"
rm -f "$PROJECT_ROOT/build-scripts/build-linux-legacy-internal.sh"
