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
echo "Step 1: Checking Qt dependencies..."

# Check for Qt
if ! pkg-config --exists Qt6Widgets 2>/dev/null && ! pkg-config --exists Qt5Widgets 2>/dev/null; then
    echo "  ⚠ Qt not found. Installing..."
    
    if [[ "$OS" == "macos" ]]; then
        brew install qt@6
        export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"
    elif [[ "$OS" == "linux" ]]; then
        echo ""
        echo "Please install Qt development packages:"
        echo "  Ubuntu/Debian 22.04+:"
        echo "    sudo apt-get install qt6-base-dev qt6-tools-dev libqt6svg6-dev"
        echo ""
        echo "  Ubuntu/Debian 20.04:"
        echo "    sudo apt-get install qtbase5-dev qttools5-dev libqt5svg5-dev"
        echo ""
        exit 1
    fi
else
    echo "  ✓ Qt found"
fi

# Additional dependencies for Linux
if [[ "$OS" == "linux" ]]; then
    echo ""
    echo "Checking additional dependencies..."
    
    if ! dpkg -l | grep -q libqrencode-dev; then
        echo "  ⚠ Please install: sudo apt-get install libqrencode-dev libdbus-1-dev"
    fi
fi

echo ""
echo "Step 2: Configuring CMake for GUI build..."

# Clean previous build (Disabled for incremental builds)
# rm -rf build-gui
mkdir -p build-gui

cmake -B build-gui -DBUILD_GUI=ON -DBUILD_TESTS=OFF -DBUILD_BENCH=OFF -DWITH_QRENCODE=ON

echo ""
echo "Step 3: Building GUI wallet..."
echo "This may take 10-20 minutes..."
echo ""

cmake --build build-gui --target bitcoin-qt -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)

echo ""
echo "========================================"
echo "✅ GUI Wallet Build Complete!"
echo "========================================"
echo ""

if [[ "$OS" == "macos" ]]; then
    if [ -d "build-gui/src/qt/BitMinti-Qt.app" ]; then
        echo "macOS Application Bundle:"
        echo "  build-gui/src/qt/BitMinti-Qt.app"
        echo ""
        echo "To run:"
        echo "  open build-gui/src/qt/BitMinti-Qt.app"
        echo ""
        echo "To create DMG installer:"
        echo "  ./create-dmg.sh"
    fi
elif [[ "$OS" == "linux" ]]; then
    if [ -f "build-gui/src/qt/bitminti-qt" ]; then
        echo "Linux Binary:"
        echo "  build-gui/src/qt/bitminti-qt"
        echo ""
        echo "To run:"
        echo "  ./build-gui/src/qt/bitminti-qt"
        echo ""
        echo "To create AppImage:"
        echo "  ./create-appimage.sh"
    fi
fi
