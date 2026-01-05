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
# Check for Qt
if ! pkg-config --exists Qt6Widgets 2>/dev/null && ! pkg-config --exists Qt5Widgets 2>/dev/null; then
    echo "  ⚠ Qt not found."
    
    if [[ "$OS" == "macos" ]]; then
        echo "Installing Qt via Homebrew..."
        brew install qt@6
        export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"
    elif [[ "$OS" == "linux" ]]; then
        echo "Missing Qt development libraries."
        
        INSTALL_CMD=""
        DISTRO="unknown"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        fi

        case "$DISTRO" in
            ubuntu|debian|pop|mint|kali)
                echo "  Detected Debian-based system."
                INSTALL_CMD="sudo apt-get update && sudo apt-get install -y qt6-base-dev qt6-tools-dev libqt6svg6-dev libqt6charts6-dev"
                ;;
            fedora|rhel|centos)
                echo "  Detected Fedora-based system."
                INSTALL_CMD="sudo dnf install -y qt6-qtbase-devel qt6-qttools-devel qt6-qtsvg-devel qt6-qtcharts-devel"
                ;;
            arch|manjaro)
                echo "  Detected Arch-based system."
                INSTALL_CMD="sudo pacman -S --noconfirm qt6-base qt6-tools qt6-svg qt6-charts"
                ;;
            *)
                echo "  ⚠ Could not detect specific distro for automatic install."
                echo "  Please install Qt6 manually (qt6-base-devel, qt6-tools-devel, qt6-svg-devel)."
                exit 1
                ;;
        esac

        if [ -n "$INSTALL_CMD" ]; then
            echo "  Attempting to install dependencies automatically..."
            echo "  Running: $INSTALL_CMD"
            eval "$INSTALL_CMD"
            
            # Re-check
            if ! pkg-config --exists Qt6Widgets 2>/dev/null; then
                 echo "  ❌ Installation failed or Qt still not found. Please install manually."
                 exit 1
            else
                 echo "  ✅ Qt installed successfully."
            fi
        fi
    fi
else
    echo "  ✓ Qt found"
fi

# Additional dependencies for Linux
if [[ "$OS" == "linux" ]]; then
    echo ""
    echo "Checking additional dependencies..."
    
    if ! pkg-config --exists libqrencode 2>/dev/null; then
         echo "  ⚠ libqrencode not found."
         
         INSTALL_CMD=""
         case "$DISTRO" in
            ubuntu|debian|pop|mint|kali)
                INSTALL_CMD="sudo apt-get install -y libqrencode-dev"
                ;;
            fedora|rhel|centos)
                INSTALL_CMD="sudo dnf install -y qrencode-devel"
                ;;
            arch|manjaro)
                INSTALL_CMD="sudo pacman -S --noconfirm qrencode"
                ;;
         esac

         if [ -n "$INSTALL_CMD" ]; then
             echo "  Running: $INSTALL_CMD"
             eval "$INSTALL_CMD"
         else
             echo "  ⚠ Skipping optional libqrencode install (unknown distro)."
         fi
    else
         echo "  ✓ libqrencode found"
    fi
fi

echo ""
echo "Step 2: Configuring CMake for GUI build..."

# Determine Project Root
# Script is in build-scripts/linux/ -> Root is ../../
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Clean previous build (Disabled for incremental builds)
# rm -rf build-linux-gui
mkdir -p build-linux-gui

echo "Configuring from root: $PROJECT_ROOT"
cmake -B build-linux-gui -S "$PROJECT_ROOT" -DBUILD_GUI=ON -DBUILD_TESTS=OFF -DBUILD_BENCH=OFF -DWITH_QRENCODE=ON

echo ""
echo "Step 3: Building GUI wallet..."
echo "This may take 10-20 minutes..."
echo ""

cmake --build build-linux-gui --target bitcoin-qt -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)

echo ""
echo "========================================"
echo "✅ GUI Wallet Build Complete!"
echo "========================================"
echo ""
echo "========================================"
echo "Step 4: Packaging for Release (AppImage)"
echo "========================================"
echo "Creating standalone executable that requires no installation..."

# Create AppDir structure
APPDIR="build-linux-gui/BitMinti.AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/128x128/apps"

# Copy binary
# Copy binary
# Priority 1: bin/ directory (standard CMake install/output location)
BIN_SOURCE="build-linux-gui/bin/bitminti-qt"

if [ ! -f "$BIN_SOURCE" ]; then
    # Priority 2: src/qt/ directory (legacy/dev location)
    BIN_SOURCE="build-linux-gui/src/qt/bitminti-qt"
fi

if [ ! -f "$BIN_SOURCE" ]; then
    # Priority 3: Fallback to 'bitcoin-qt' naming
    BIN_SOURCE="build-linux-gui/src/qt/bitcoin-qt"
fi

if [ ! -f "$BIN_SOURCE" ]; then
    echo "ERROR: Could not find compiled binary. Checked:"
    echo "  - build-linux-gui/bin/bitminti-qt"
    echo "  - build-linux-gui/src/qt/bitminti-qt"
    echo "  - build-linux-gui/src/qt/bitcoin-qt"
    exit 1
fi

echo "  Found binary: $BIN_SOURCE"
cp "$BIN_SOURCE" "$APPDIR/usr/bin/bitminti-qt"

# Create Desktop File
cat > "$APPDIR/usr/share/applications/bitminti.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=BitMinti
Exec=bitminti-qt %u
Icon=bitminti
Categories=Office;Finance;
EOF

# Copy Icon (Placeholder or real)
ICON_SRC="src/qt/res/icons/bitcoin.png"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$APPDIR/usr/share/icons/hicolor/128x128/apps/bitminti.png"
    cp "$ICON_SRC" "$APPDIR/bitminti.png"
else
    touch "$APPDIR/bitminti.png"
fi

# Download bundling tool (linuxdeployqt) if missing
if [ ! -f "linuxdeployqt-x86_64.AppImage" ]; then
    echo "  Downloading linuxdeployqt..."
    wget -q -c "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
    chmod +x linuxdeployqt-continuous-x86_64.AppImage
fi

# Run the bundler
echo "  Bundling libraries into AppImage..."
# -unsupported-allow-new-glibc is needed because we are building on a modern OS
# This means the resulting file works on this OS and newer, but might not work on very old ones.
export VERSION="1.0.0" # Prevents prompts
./linuxdeployqt-continuous-x86_64.AppImage "$APPDIR/usr/share/applications/bitminti.desktop" -appimage -unsupported-allow-new-glibc -no-translations

echo ""
echo "========================================"
echo "✅ BUILD COMPLETE!"
echo "========================================"
echo "Your standalone wallet file is here:"
ls -lh BitMinti-*.AppImage
echo ""
echo "Users can download this file, make it executable, and run it directly."
