#!/bin/bash
# Create DMG for BitMinti-Qt
# Includes bundle repair and signing.

APP_PATH="build-gui/BitMinti-Qt.app"
BINARY_SOURCE="build-gui/bin/bitminti-qt"
DMG_NAME="BitMinti-Qt.dmg"
VOL_NAME="BitMinti"

# 1. Handle Naming Quirk
if [ -d "build-gui/Bitcoin-Qt.app" ]; then
    echo "Renaming Bitcoin-Qt.app to BitMinti-Qt.app..."
    rm -rf "$APP_PATH"
    mv "build-gui/Bitcoin-Qt.app" "$APP_PATH"
fi

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not found at $APP_PATH"
    echo "Please build the GUI first."
    exit 1
fi

# 2. Repair Bundle Structure (Fix 'Damaged App' error)
if [ ! -d "$APP_PATH/Contents/MacOS" ]; then
    echo "Reparing App Bundle Structure..."
    mkdir -p "$APP_PATH/Contents/MacOS"
    
    # Try finding the binary
    if [ ! -f "$BINARY_SOURCE" ]; then
        # Check potential alternative location
         if [ -f "build-gui/src/qt/bitminti-qt" ]; then
            BINARY_SOURCE="build-gui/src/qt/bitminti-qt"
         elif [ -f "build-gui/bin/bitcoin-qt" ]; then
             BINARY_SOURCE="build-gui/bin/bitcoin-qt"
         fi
    fi

    if [ -f "$BINARY_SOURCE" ]; then
        echo "Copying binary from $BINARY_SOURCE..."
        cp "$BINARY_SOURCE" "$APP_PATH/Contents/MacOS/BitMinti-Qt"
        chmod +x "$APP_PATH/Contents/MacOS/BitMinti-Qt"
    else
        echo "Warning: Compiled binary not found. Bundle might be incomplete."
    fi
    
    # Update Info.plist
    PLIST="$APP_PATH/Contents/Info.plist"
    if [ -f "$PLIST" ]; then
        sed -i '' 's/Bitcoin-Qt/BitMinti-Qt/g' "$PLIST"
    fi
    
    # Remove quarantine
    xattr -cr "$APP_PATH"
fi

# 2.5. Deploy Qt Frameworks (Critical for running on other machines)
# This bundles QtWidgets, QtCore, etc. inside the app.
echo "Deploying Qt Frameworks..."

# Find macdeployqt
if command -v macdeployqt >/dev/null 2>&1; then
    MACDEPLOYQT=$(type -p macdeployqt) # Get full path
elif [ -f "/usr/local/opt/qt/bin/macdeployqt" ]; then
    MACDEPLOYQT="/usr/local/opt/qt/bin/macdeployqt" # Intel Homebrew
elif [ -f "/opt/homebrew/opt/qt/bin/macdeployqt" ]; then
    MACDEPLOYQT="/opt/homebrew/opt/qt/bin/macdeployqt" # Apple Silicon Homebrew
else
    echo "Warning: macdeployqt not found. App will crash on other machines."
    MACDEPLOYQT=""
fi

if [ -n "$MACDEPLOYQT" ]; then
    # Derive QT_LIB_DIR from macdeployqt path (../bin/macdeployqt -> ../lib)
    QT_BIN_DIR=$(dirname "$MACDEPLOYQT")
    QT_LIB_DIR=$(dirname "$QT_BIN_DIR")/lib

    echo "Using macdeployqt: $MACDEPLOYQT"
    echo "Using Qt Lib Dir: $QT_LIB_DIR"

    "$MACDEPLOYQT" "$APP_PATH" -libpath="$QT_LIB_DIR" -always-overwrite -verbose=1
    if [ $? -ne 0 ]; then
        echo "Error: macdeployqt failed."
        exit 1
    fi
    echo "Qt Deployment Complete."
fi

# 3. Sign App Bundle (Ad-Hoc)
echo "Signing App Bundle (Ad-Hoc)..."
codesign --force --deep --sign - "$APP_PATH"
if [ $? -ne 0 ]; then
    echo "Warning: Code signing failed. DMG may not open on some systems."
fi

# 4. Create DMG
echo "Creating DMG..."

# Create Staging Directory
STAGING_DIR="build-gui/dmg-staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy App to Staging
cp -R "$APP_PATH" "$STAGING_DIR/"

# Create /Applications symlink
ln -s /Applications "$STAGING_DIR/Applications"

# Remove previous DMG
rm -f "$DMG_NAME"

# Create DMG from Staging Dir
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

echo ""
if [ -f "$DMG_NAME" ]; then
    echo "✅ DMG Created Successfully: $DMG_NAME"
else
    echo "❌ Failed to create DMG."
fi
