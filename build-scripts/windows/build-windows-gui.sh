#!/bin/bash
# BitMinti Windows GUI Wallet Build Script
# Cross-compiles Windows GUI wallet (.exe) from Linux/Mac

set -e

# Resolve locations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "========================================"
echo "BitMinti Windows GUI Build Script"
echo "========================================"
echo "Project Root: $PROJECT_ROOT"
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

# Check for mingw-w64
if ! command -v x86_64-w64-mingw32-g++ &> /dev/null; then
    echo "ERROR: mingw-w64 not found!"
    echo ""
    echo "Install it with:"
    echo "  Ubuntu/Debian: sudo apt-get install g++-mingw-w64-x86-64"
    echo "  macOS: brew install mingw-w64"
    exit 1
fi

echo ""
echo "Step 1: Building dependencies for Windows (with Qt)..."
echo "This may take 60-90 minutes on first run."
echo ""

cd "$PROJECT_ROOT/depends"
make HOST=x86_64-w64-mingw32 -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)
cd ..

echo ""
echo "Step 2: Configuring CMake for Windows GUI build..."
echo ""

# Clean previous build
rm -rf "$PROJECT_ROOT/build-windows-gui"
mkdir -p "$PROJECT_ROOT/build-windows-gui"

cmake -B "$PROJECT_ROOT/build-windows-gui" \
    -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/depends/x86_64-w64-mingw32/toolchain.cmake" \
    -DBUILD_GUI=ON \
    -DBUILD_TESTS=OFF \
    -DBUILD_BENCH=OFF

echo ""
echo "Step 3: Building Windows GUI binaries..."
echo ""

cmake --build "$PROJECT_ROOT/build-windows-gui" --target bitcoin-qt bitmintid bitminti-cli -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)

echo ""
echo "========================================"
echo "✅ Windows GUI Build Complete!"
echo "========================================"
echo ""
echo "Binaries location:"
echo "  $PROJECT_ROOT/build-windows-gui/src/qt/bitcoin-qt.exe (GUI Wallet)"
echo "  $PROJECT_ROOT/build-windows-gui/src/bitmintid.exe"
echo "  $PROJECT_ROOT/build-windows-gui/src/bitminti-cli.exe"
echo ""

# Create release package
if [ -f "$PROJECT_ROOT/build-windows-gui/src/qt/bitcoin-qt.exe" ]; then
    echo "Creating Windows GUI release package..."
    RELEASE_DIR="$PROJECT_ROOT/bitminti-windows-gui-x64"
    rm -rf "$RELEASE_DIR"
    mkdir -p "$RELEASE_DIR"
    
    cp "$PROJECT_ROOT/build-windows-gui/src/qt/bitcoin-qt.exe" "$RELEASE_DIR/bitminti-qt.exe"
    cp "$PROJECT_ROOT/build-windows-gui/src/bitmintid.exe" "$RELEASE_DIR/"
    cp "$PROJECT_ROOT/build-windows-gui/src/bitminti-cli.exe" "$RELEASE_DIR/"
    cp "$PROJECT_ROOT/dist/mine-windows.bat" "$RELEASE_DIR/"
    cp "$PROJECT_ROOT/ONE_CLICK_MINING.md" "$RELEASE_DIR/"
    cp "$PROJECT_ROOT/README.md" "$RELEASE_DIR/"
    
    # Create a simple README for GUI
    cat > "$RELEASE_DIR/START_HERE.txt" << 'EOF'
BitMinti Windows Wallet - Quick Start
======================================

OPTION 1: Graphical Wallet (Easiest)
-------------------------------------
Double-click: bitminti-qt.exe

This opens the full graphical wallet where you can:
- Create/manage wallets
- Send/receive BitMinti
- Mine with one click
- View transaction history


OPTION 2: One-Click Mining (Command Line)
------------------------------------------
Double-click: mine-windows.bat

This automatically:
- Starts the mining software
- Creates a wallet
- Begins mining BitMinti


OPTION 3: Manual/Advanced (Command Line)
-----------------------------------------
1. Start daemon: bitmintid.exe
2. Use CLI: bitminti-cli.exe


For more help, see: ONE_CLICK_MINING.md

Website: https://bitminti.com
EOF
    
    cd "$PROJECT_ROOT"
    zip -r "bitminti-windows-gui-x64.zip" "bitminti-windows-gui-x64"
    
    echo ""
    echo "Release package created: $PROJECT_ROOT/bitminti-windows-gui-x64.zip"
    echo "Ready for distribution!"
fi

echo ""
echo "To test (requires Wine on Linux/Mac):"
echo "  wine $PROJECT_ROOT/build-windows-gui/src/qt/bitcoin-qt.exe"
