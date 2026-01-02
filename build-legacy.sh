#!/bin/bash
set -e

# 1. Build the docker image
echo "Building Docker image..."
docker build -t btc3-legacy -f Dockerfile.legacy .

# 2. Run the build inside the container
echo "Running build inside container..."
docker run --rm -v $(pwd):/btc5 -w /btc5 btc3-legacy /bin/bash -c "
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
