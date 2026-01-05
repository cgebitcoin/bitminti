#!/bin/bash
# BitMinti Linux/macOS GUI Wallet Build Script
# Builds the graphical wallet (Bitcoin-Qt style) for Linux and macOS
# Usage: ./build-scripts/build-linux-gui.sh

set -e

echo "========================================"
echo "BitMinti GUI Wallet Builder"
echo "========================================"
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected: macOS"
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected: Linux"
    OS="linux"
else
    echo "ERROR: Unsupported OS: $OSTYPE"
    exit 1
fi

echo ""
# ==============================================================================
# BITCOIN CORE "DEPENDS" BUILD SYSTEM (STATIC LINKING)
# ==============================================================================
# This method builds all dependencies (Qt, libevent, etc.) from source
# and links them statically. The result is a single binary that runs on any Linux.

# Determine Project Root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEPENDS_DIR="$PROJECT_ROOT/depends"

# 1. Build Dependencies
echo "Step 1: Building Static Dependencies (this takes a while)..."
echo "Target: x86_64-pc-linux-gnu"

cd "$DEPENDS_DIR"

# DISK SPACE SAVER MODE: Build dependencies one by one and clean up
# This prevents the "work" directory from growing to 20GB+.

# 1. Base dependencies (Non-Qt)
echo "   [1/3] Building Base Dependencies..."
make HOST=x86_64-pc-linux-gnu -j$(nproc) NO_QT=1
echo "   -> Cleaning base artifacts..."
rm -rf work sources

# 2. Qt (The biggest one)
echo "   [2/3] Building Qt (this is huge)..."
make HOST=x86_64-pc-linux-gnu -j$(nproc) qt
echo "   -> Cleaning Qt artifacts..."
rm -rf work sources

# 3. Everything else (Final pass to catch anything missed)
echo "   [3/3] Finalizing Dependencies..."
make HOST=x86_64-pc-linux-gnu -j$(nproc)
echo "   -> Final cleanup..."
rm -rf work sources

cd "$PROJECT_ROOT"

# 2. Configure with Static Libs
echo ""
echo "Step 2: Configuring Build..."
DEPENDS_PREFIX="$DEPENDS_DIR/x86_64-pc-linux-gnu"

if [ ! -f "$DEPENDS_PREFIX/share/toolchain.cmake" ]; then
    echo "ERROR: Toolchain file not found at $DEPENDS_PREFIX/share/toolchain.cmake"
    echo "Depends build likely failed."
    exit 1
fi

# Clean old build
rm -rf build-linux-gui
mkdir -p build-linux-gui

# We use the depends prefix to tell CMake where our static libs are
# -DCMAKE_TOOLCHAIN_FILE is crucial here for cross-compilation/static environment
echo "Configuring from root: $PROJECT_ROOT"
cmake -B build-linux-gui -S . \
    -DCMAKE_TOOLCHAIN_FILE="$DEPENDS_PREFIX/share/toolchain.cmake" \
    -DBUILD_GUI=ON \
    -DBUILD_TESTS=OFF \
    -DBUILD_BENCH=OFF \
    -DENABLE_ZMQ=OFF

# 3. Build the Static Binary
echo ""
echo "Step 3: Building Static Binary..."
cmake --build build-linux-gui --target bitcoin-qt -j$(nproc)

echo ""
echo "========================================"
echo "✅ STATIC BUILD COMPLETE!"
echo "========================================"

# 4. Cleanup and Output
echo "Step 4: Cleanup & Output..."

# Move binary to root
OUTPUT_BIN="./bitminti-qt-linux"
if [ -f "build-linux-gui/src/qt/bitminti-qt" ]; then
    cp build-linux-gui/src/qt/bitminti-qt "$OUTPUT_BIN"
    strip "$OUTPUT_BIN"
    echo "✅ Binary moved to: $OUTPUT_BIN"
else
    echo "❌ Error: Binary not found at build-linux-gui/src/qt/bitminti-qt"
    exit 1
fi

echo "Cleaning up build directories to save disk space (as requested)..."
rm -rf build-linux-gui
echo "  - Removed build-linux-gui/"

if [ -d "$DEPENDS_DIR/sources" ]; then
    rm -rf "$DEPENDS_DIR/sources"
    echo "  - Removed depends/sources/"
fi

if [ -d "$DEPENDS_DIR/work" ]; then
    rm -rf "$DEPENDS_DIR/work"
    echo "  - Removed depends/work/"
fi

echo ""
echo "Space saved. Your wallet is ready: $OUTPUT_BIN"
