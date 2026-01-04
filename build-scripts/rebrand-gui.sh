#!/bin/bash
# BitMinti GUI Rebranding Script
# Replaces all Bitcoin logos and icons with BitMinti branding

set -e

echo "========================================"
echo "BitMinti GUI Rebranding"
echo "========================================"
echo ""

# Check if logo files exist
if [ ! -f "website/logo.png" ]; then
    echo "ERROR: website/logo.png not found!"
    echo "Please ensure you have the BitMinti logo in the website/ directory"
    exit 1
fi

echo "Step 1: Backing up original Bitcoin icons..."
BACKUP_DIR="src/qt/res/icons/bitcoin_original_backup"
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    cp src/qt/res/icons/bitcoin* "$BACKUP_DIR/" 2>/dev/null || true
    cp src/qt/res/src/bitcoin.svg "$BACKUP_DIR/" 2>/dev/null || true
    echo "  ✓ Backup created in $BACKUP_DIR"
else
    echo "  ⚠ Backup already exists, skipping"
fi

echo ""
echo "Step 2: Preparing BitMinti logo for different formats..."

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "  ⚠ ImageMagick not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install imagemagick
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "  Please install ImageMagick:"
        echo "    Ubuntu/Debian: sudo apt-get install imagemagick"
        echo "    Fedora: sudo dnf install ImageMagick"
        exit 1
    fi
fi

# Create temporary working directory
TEMP_DIR=$(mktemp -d)
echo "  Working directory: $TEMP_DIR"

# Copy logo to temp
cp website/logo.png "$TEMP_DIR/logo_source.png"

echo ""
echo "Step 3: Converting logo to required formats..."

# Convert to ICO (Windows icon) - multiple sizes
convert "$TEMP_DIR/logo_source.png" -resize 256x256 \
    \( -clone 0 -resize 16x16 \) \
    \( -clone 0 -resize 32x32 \) \
    \( -clone 0 -resize 48x48 \) \
    \( -clone 0 -resize 64x64 \) \
    \( -clone 0 -resize 128x128 \) \
    -delete 0 -colors 256 "$TEMP_DIR/bitminti.ico"
echo "  ✓ Created .ico file"

# Convert to ICNS (macOS icon)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # On macOS, use iconutil
    ICONSET_DIR="$TEMP_DIR/bitminti.iconset"
    mkdir -p "$ICONSET_DIR"
    
    convert "$TEMP_DIR/logo_source.png" -resize 16x16 "$ICONSET_DIR/icon_16x16.png"
    convert "$TEMP_DIR/logo_source.png" -resize 32x32 "$ICONSET_DIR/icon_16x16@2x.png"
    convert "$TEMP_DIR/logo_source.png" -resize 32x32 "$ICONSET_DIR/icon_32x32.png"
    convert "$TEMP_DIR/logo_source.png" -resize 64x64 "$ICONSET_DIR/icon_32x32@2x.png"
    convert "$TEMP_DIR/logo_source.png" -resize 128x128 "$ICONSET_DIR/icon_128x128.png"
    convert "$TEMP_DIR/logo_source.png" -resize 256x256 "$ICONSET_DIR/icon_128x128@2x.png"
    convert "$TEMP_DIR/logo_source.png" -resize 256x256 "$ICONSET_DIR/icon_256x256.png"
    convert "$TEMP_DIR/logo_source.png" -resize 512x512 "$ICONSET_DIR/icon_256x256@2x.png"
    convert "$TEMP_DIR/logo_source.png" -resize 512x512 "$ICONSET_DIR/icon_512x512.png"
    convert "$TEMP_DIR/logo_source.png" -resize 1024x1024 "$ICONSET_DIR/icon_512x512@2x.png"
    
    iconutil -c icns "$ICONSET_DIR" -o "$TEMP_DIR/bitminti.icns"
    echo "  ✓ Created .icns file (macOS)"
else
    # On Linux, use png2icns if available, otherwise use ImageMagick
    if command -v png2icns &> /dev/null; then
        png2icns "$TEMP_DIR/bitminti.icns" "$TEMP_DIR/logo_source.png"
    else
        # Fallback: create a simple icns with ImageMagick
        convert "$TEMP_DIR/logo_source.png" -resize 512x512 "$TEMP_DIR/bitminti.icns"
    fi
    echo "  ✓ Created .icns file"
fi

# Convert to standard PNG sizes
convert "$TEMP_DIR/logo_source.png" -resize 1024x1024 "$TEMP_DIR/bitminti.png"
echo "  ✓ Created .png file"

# Copy SVG if it exists
if [ -f "website/logo.svg" ]; then
    cp website/logo.svg "$TEMP_DIR/bitminti.svg"
    echo "  ✓ Copied .svg file"
fi

echo ""
echo "Step 4: Replacing Bitcoin icons with BitMinti..."

# Replace main icon
cp "$TEMP_DIR/bitminti.png" src/qt/res/icons/bitcoin.png
echo "  ✓ Replaced bitcoin.png"

# Replace ICO
cp "$TEMP_DIR/bitminti.ico" src/qt/res/icons/bitcoin.ico
cp "$TEMP_DIR/bitminti.ico" src/qt/res/icons/bitcoin_testnet.ico
cp "$TEMP_DIR/bitminti.ico" src/qt/res/icons/bitcoin_signet.ico
echo "  ✓ Replaced .ico files"

# Replace ICNS
cp "$TEMP_DIR/bitminti.icns" src/qt/res/icons/bitcoin.icns
echo "  ✓ Replaced .icns file"

# Replace SVG
if [ -f "$TEMP_DIR/bitminti.svg" ]; then
    cp "$TEMP_DIR/bitminti.svg" src/qt/res/src/bitcoin.svg
    echo "  ✓ Replaced bitcoin.svg"
fi

echo ""
echo "Step 5: Updating Qt resource file..."

# Update the application name in the Qt resource file if needed
if [ -f "src/qt/bitcoin.qrc" ]; then
    sed -i.bak 's/Bitcoin Core/BitMinti/g' src/qt/bitcoin.qrc
    echo "  ✓ Updated bitcoin.qrc"
fi

echo ""
echo "Step 6: Updating application strings..."

# Update window titles and application names
if [ -f "src/qt/bitcoingui.cpp" ]; then
    sed -i.bak 's/Bitcoin Core/BitMinti/g' src/qt/bitcoingui.cpp
    echo "  ✓ Updated bitcoingui.cpp"
fi

# Update about dialog
if [ -f "src/qt/forms/aboutdialog.ui" ]; then
    sed -i.bak 's/Bitcoin Core/BitMinti/g' src/qt/forms/aboutdialog.ui
    sed -i.bak 's/<b>Bitcoin</b>/<b>BitMinti</b>/g' src/qt/forms/aboutdialog.ui
    echo "  ✓ Updated aboutdialog.ui"
fi

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo ""
echo "========================================"
echo "✅ GUI Rebranding Complete!"
echo "========================================"
echo ""
echo "Changed files:"
echo "  • src/qt/res/icons/bitcoin.png"
echo "  • src/qt/res/icons/bitcoin.ico"
echo "  • src/qt/res/icons/bitcoin.icns"
echo "  • src/qt/res/src/bitcoin.svg"
echo "  • src/qt/bitcoingui.cpp"
echo "  • src/qt/forms/aboutdialog.ui"
echo ""
echo "Original files backed up in: $BACKUP_DIR"
echo ""
echo "Next step: Build the GUI wallet with:"
echo "  ./build-gui.sh"
