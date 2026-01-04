# Building Windows Binaries for BitMinti

This guide shows how to create Windows `.exe` files from Mac or Linux.

## Quick Start

```bash
./build-windows.sh
```

That's it! The script will:
1. Install required tools (mingw-w64)
2. Build all dependencies for Windows
3. Compile bitmintid.exe and bitminti-cli.exe
4. Create a release package

**Build time:** 30-60 minutes on first run (dependencies are cached for future builds)

---

## Prerequisites

### On Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    cmake \
    g++-mingw-w64-x86-64 \
    autoconf \
    automake \
    pkg-config \
    zip
```

### On macOS:
```bash
brew install mingw-w64 cmake autoconf automake pkg-config
```

### On Fedora:
```bash
sudo dnf install -y \
    cmake \
    mingw64-gcc-c++ \
    autoconf \
    automake \
    pkgconfig \
    zip
```

---

## Manual Build (Step-by-Step)

If you prefer to understand the process:

### 1. Build Dependencies

```bash
cd depends
make HOST=x86_64-w64-mingw32 -j$(nproc)
cd ..
```

This builds all libraries (boost, libevent, etc.) for Windows.

### 2. Configure CMake

```bash
cmake -B build-windows \
    -DCMAKE_TOOLCHAIN_FILE="${PWD}/depends/x86_64-w64-mingw32/toolchain.cmake" \
    -DBUILD_GUI=OFF \
    -DBUILD_TESTS=OFF
```

### 3. Build Binaries

```bash
cmake --build build-windows --target bitmintid bitminti-cli -j$(nproc)
```

### 4. Output

Your Windows executables will be in:
- `build-windows/src/bitmintid.exe`
- `build-windows/src/bitminti-cli.exe`

---

## Testing Windows Binaries (on Linux/Mac)

Install Wine to test Windows executables:

### Ubuntu/Debian:
```bash
sudo apt-get install wine64
wine build-windows/src/bitmintid.exe --version
```

### macOS:
```bash
brew install --cask wine-stable
wine64 build-windows/src/bitmintid.exe --version
```

---

## Creating a Release Package

```bash
# Create release directory
mkdir -p bitminti-windows-x64

# Copy binaries
cp build-windows/src/bitmintid.exe bitminti-windows-x64/
cp build-windows/src/bitminti-cli.exe bitminti-windows-x64/

# Copy one-click miner and docs
cp mine-windows.bat bitminti-windows-x64/
cp ONE_CLICK_MINING.md bitminti-windows-x64/
cp README.md bitminti-windows-x64/

# Create zip
zip -r bitminti-windows-x64.zip bitminti-windows-x64
```

Now you can upload `bitminti-windows-x64.zip` to GitHub Releases!

---

## Common Issues

### "mingw-w64 not found"
Install the cross-compiler:
```bash
# Ubuntu/Debian
sudo apt-get install g++-mingw-w64-x86-64

# macOS
brew install mingw-w64
```

### "Could not find toolchain file"
Make sure you've built the dependencies first:
```bash
cd depends
make HOST=x86_64-w64-mingw32 -j$(nproc)
```

### Build fails with "undefined reference"
Clean and rebuild:
```bash
rm -rf build-windows
./build-windows.sh
```

---

## Building for Different Windows Versions

The default build targets Windows 10+ (64-bit). To support older versions:

```bash
# In depends/Makefile, before building
export CFLAGS="-D_WIN32_WINNT=0x0601"  # Windows 7
```

---

## GitHub Actions (Automated Builds)

To automatically build Windows binaries on every commit, add this to `.github/workflows/build.yml`:

```yaml
name: Windows Build

on: [push, pull_request]

jobs:
  build-windows:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y g++-mingw-w64-x86-64
      
      - name: Build Windows binaries
        run: ./build-windows.sh
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: bitminti-windows-x64
          path: bitminti-windows-x64.zip
```

---

## Security Note

**Important:** When distributing Windows binaries:

1. **Code sign** your executables (prevents Windows Defender warnings)
2. **Verify checksums** in your release notes
3. **Build deterministically** (same source = same binary)

### Generate SHA256 Checksums:
```bash
sha256sum bitminti-windows-x64.zip > bitminti-windows-x64.zip.sha256
```

---

## Next Steps

After building:
1. Test the executables on a real Windows machine
2. Upload to GitHub Releases
3. Announce on Reddit/Twitter
4. Update the website download links

Happy building! 🏗️
