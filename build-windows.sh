#!/bin/bash
# BitMinti Windows Cross-Compilation Script
# This builds Windows executables (.exe) from Linux/Mac

set -e

echo "========================================"
echo "BitMinti Windows Build Script"
echo "========================================"
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected: macOS"
    OS="macos"
    # Install mingw-w64 if not present
    if ! command -v x86_64-w64-mingw32-g++ &> /dev/null; then
        echo "Installing mingw-w64 via Homebrew..."
        brew install mingw-w64
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected: Linux"
    OS="linux"
    # Check for mingw-w64
    if ! command -v x86_64-w64-mingw32-g++ &> /dev/null; then
        echo "ERROR: mingw-w64 not found!"
        echo ""
        echo "Install it with:"
        echo "  Ubuntu/Debian: sudo apt-get install g++-mingw-w64-x86-64"
        echo "  Fedora: sudo dnf install mingw64-gcc-c++"
        exit 1
    fi
else
    echo "ERROR: Unsupported OS: $OSTYPE"
    exit 1
fi

echo ""
echo "Step 1: Building dependencies for Windows..."
echo "This may take 30-60 minutes on first run."
echo ""

cd depends
make HOST=x86_64-w64-mingw32 -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)
cd ..

echo ""
echo "Step 2: Configuring CMake for Windows build..."
echo ""

# Clean previous build
rm -rf build-windows
mkdir -p build-windows

cmake -B build-windows \
    -DCMAKE_TOOLCHAIN_FILE="${PWD}/depends/x86_64-w64-mingw32/toolchain.cmake" \
    -DBUILD_GUI=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_BENCH=OFF

echo ""
echo "Step 3: Building Windows binaries..."
echo ""

cmake --build build-windows --target bitmintid bitminti-cli -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)

echo ""
echo "========================================"
echo "✅ Windows Build Complete!"
echo "========================================"
echo ""
echo "Binaries location:"
echo "  build-windows/src/bitmintid.exe"
echo "  build-windows/src/bitminti-cli.exe"
echo ""

# Create release package
if [ -f "build-windows/src/bitmintid.exe" ]; then
    echo "Creating Windows release package..."
    RELEASE_DIR="bitminti-windows-x64"
    rm -rf "$RELEASE_DIR"
    mkdir -p "$RELEASE_DIR"
    
    cp build-windows/src/bitmintid.exe "$RELEASE_DIR/"
    cp build-windows/src/bitminti-cli.exe "$RELEASE_DIR/"
    cp mine-windows.bat "$RELEASE_DIR/"
    cp ONE_CLICK_MINING.md "$RELEASE_DIR/"
    cp README.md "$RELEASE_DIR/"
    
    zip -r "${RELEASE_DIR}.zip" "$RELEASE_DIR"
    
    echo ""
    echo "Release package created: ${RELEASE_DIR}.zip"
    echo "Ready for distribution!"
fi

echo ""
echo "To test (requires Wine on Linux/Mac):"
echo "  wine build-windows/src/bitmintid.exe --version"
