#!/bin/bash
set -e

# Resolve locations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "========================================"
echo "BitMinti Legacy Build (Docker)"
echo "========================================"
echo "Project Root: $PROJECT_ROOT"
echo ""

# 1. Build the docker image
echo "Building Docker image..."
docker build -t btc3-legacy -f "$PROJECT_ROOT/Dockerfile.legacy" "$PROJECT_ROOT"

# 2. Run the build inside the container
echo "Running build inside container..."
docker run --rm -v "$PROJECT_ROOT":/btc5 -w /btc5 btc3-legacy /bin/bash -c "
    echo 'Building dependencies...' &&
    cd depends &&
    make HOST=x86_64-pc-linux-gnu NO_QT=1 -j\$(nproc) &&
    cd .. &&
    echo 'Building project...' &&
    rm -rf build-legacy &&
    cmake -B build-legacy -DCMAKE_TOOLCHAIN_FILE=depends/x86_64-pc-linux-gnu/toolchain.cmake &&
    cmake --build build-legacy -j\$(nproc) --target bitmintid bitminti-cli
"

echo "Build complete! Artifacts are in build-legacy/src/"
