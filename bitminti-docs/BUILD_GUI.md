# Building BitMinti GUI Wallet

Complete guide for building the graphical wallet with BitMinti branding.

## Quick Start

```bash
# 1. Rebrand the GUI (replace Bitcoin logos with BitMinti)
./rebrand-gui.sh

# 2. Build GUI wallet for your platform
./build-gui.sh              # Linux/macOS
./build-windows-gui.sh      # Windows (cross-compile)
```

---

## Step-by-Step Guide

### Step 1: Install Dependencies

#### Ubuntu/Debian 22.04+
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential cmake \
    qt6-base-dev qt6-tools-dev libqt6svg6-dev \
    libqrencode-dev libdbus-1-dev \
    imagemagick
```

#### Ubuntu/Debian 20.04
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential cmake \
    qtbase5-dev qttools5-dev libqt5svg5-dev \
    libqrencode-dev libdbus-1-dev \
    imagemagick
```

#### macOS
```bash
brew install qt@6 cmake imagemagick qrencode
```

#### For Windows Cross-Compilation
```bash
# Ubuntu/Debian
sudo apt-get install g++-mingw-w64-x86-64 imagemagick

# macOS
brew install mingw-w64 imagemagick
```

---

### Step 2: Rebrand the GUI

This replaces all Bitcoin logos with BitMinti branding:

```bash
./rebrand-gui.sh
```

**What it does:**
- 🔄 Converts `website/logo.png` to all required formats (.ico, .icns, .svg)
- 🖼️ Replaces Bitcoin icons in `src/qt/res/icons/`
- 📝 Updates application strings (Window titles, About dialog)
- 💾 Backs up original files to `src/qt/res/icons/bitcoin_original_backup/`

---

### Step 3: Build the GUI Wallet

#### For Linux/macOS:
```bash
./build-gui.sh
```

Output:
- **Linux:** `build-gui/src/qt/bitcoin-qt`
- **macOS:** `build-gui/src/qt/Bitcoin-Qt.app`

#### For Windows (from Linux/Mac):
```bash
./build-windows-gui.sh
```

Output:
- `build-windows-gui/src/qt/bitcoin-qt.exe`
- Plus a packaged `.zip` file ready for distribution

---

## Testing the GUI

### Linux
```bash
./build-gui/src/qt/bitcoin-qt
```

### macOS
```bash
open build-gui/src/qt/Bitcoin-Qt.app
```

### Windows (using Wine on Linux)
```bash
wine build-windows-gui/src/qt/bitcoin-qt.exe
```

---

## Customizing the Logo

If you want to use a different logo:

1. Replace `website/logo.png` with your new logo (must be PNG, 1024x1024 recommended)
2. Optionally replace `website/logo.svg` (for vector graphics)
3. Run `./rebrand-gui.sh` again

---

## Manual Logo Replacement

If you want to do it manually without the script:

### Required Icon Formats:

1. **bitcoin.png** - Main icon (1024x1024 PNG)
2. **bitcoin.ico** - Windows icon (multi-size)
3. **bitcoin.icns** - macOS icon bundle
4. **bitcoin.svg** - Vector graphic

### Using ImageMagick to Convert:

```bash
# Create ICO (Windows)
convert logo.png -resize 256x256 \
    \( -clone 0 -resize 16x16 \) \
    \( -clone 0 -resize 32x32 \) \
    \( -clone 0 -resize 48x48 \) \
    -delete 0 -colors 256 bitcoin.ico

# Create ICNS (macOS - on macOS only)
mkdir icon.iconset
sips -z 16 16     logo.png --out icon.iconset/icon_16x16.png
sips -z 32 32     logo.png --out icon.iconset/icon_16x16@2x.png
sips -z 32 32     logo.png --out icon.iconset/icon_32x32.png
sips -z 64 64     logo.png --out icon.iconset/icon_32x32@2x.png
sips -z 128 128   logo.png --out icon.iconset/icon_128x128.png
sips -z 256 256   logo.png --out icon.iconset/icon_128x128@2x.png
sips -z 256 256   logo.png --out icon.iconset/icon_256x256.png
sips -z 512 512   logo.png --out icon.iconset/icon_256x256@2x.png
sips -z 512 512   logo.png --out icon.iconset/icon_512x512.png
sips -z 1024 1024 logo.png --out icon.iconset/icon_512x512@2x.png
iconutil -c icns icon.iconset
```

Then copy to:
- `src/qt/res/icons/bitcoin.png`
- `src/qt/res/icons/bitcoin.ico`
- `src/qt/res/icons/bitcoin.icns`
- `src/qt/res/src/bitcoin.svg`

---

## Troubleshooting

### "Qt not found"
Install Qt development packages (see Step 1 above).

### "ImageMagick not found"
```bash
# Ubuntu/Debian
sudo apt-get install imagemagick

# macOS
brew install imagemagick
```

### "iconutil: command not found" (on Linux)
Linux doesn't have `iconutil`. The script will use ImageMagick as a fallback.

### GUI doesn't show BitMinti logo
1. Make sure you ran `./rebrand-gui.sh` BEFORE building
2. Clean the build and try again:
   ```bash
   rm -rf build-gui
   ./build-gui.sh
   ```

### Windows build fails with Qt errors
The depends system should build Qt automatically. If it fails:
```bash
cd depends
make HOST=x86_64-w64-mingw32 qt -j$(nproc)
cd ..
```

---

## Creating Distribution Packages

### Windows Installer
After building, you'll have:
- `bitminti-windows-gui-x64.zip` - Ready to distribute!

### macOS DMG
```bash
# TODO: Add create-dmg.sh script
```

### Linux AppImage
```bash
# TODO: Add create-appimage.sh script
```

---

## Advanced: Additional Branding Changes

### Change Application Name in Code

Edit `src/qt/bitcoingui.cpp`:
```cpp
// Find and replace
setWindowTitle(tr("Bitcoin Core"));
// with
setWindowTitle(tr("BitMinti Wallet"));
```

### Change About Dialog

Edit `src/qt/forms/aboutdialog.ui` (XML file):
```xml
<!-- Find and update -->
<string>&lt;b&gt;Bitcoin&lt;/b&gt;</string>
<!-- to -->
<string>&lt;b&gt;BitMinti&lt;/b&gt;</string>
```

### After Manual Changes

Rebuild:
```bash
cmake --build build-gui --target bitcoin-qt -j$(nproc)
```

---

## Screenshots

The GUI wallet includes:
- 💼 Wallet overview (balance, recent transactions)
- 📤 Send/Receive tabs
- 📜 Transaction history
- ⚙️ Settings and preferences
- ⛏️ Mining interface (if enabled)

---

## Next Steps

1. Build and test the GUI on all platforms
2. Create professional screenshots for the website
3. Write user documentation
4. Create video tutorials for beginners

---

For support, visit: https://bitminti.com
