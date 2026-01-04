#!/bin/bash
set -e

echo "=== BitMinti Legacy Build System Setup ==="

# --- Part 1: Install Docker if missing ---
if ! command -v docker &> /dev/null; then
    echo "[+] Docker not found. Installing..."
    
    # Remove old versions
    sudo apt-get remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc 2>/dev/null || true

    # Add GPG key
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    # Handle if key already exists
    if [ -f /etc/apt/keyrings/docker.gpg ]; then
        sudo rm /etc/apt/keyrings/docker.gpg
    fi
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Repo
    echo \
      "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "[+] Docker is already installed."
fi

# --- Part 2: Permissions ---
echo "[+] Configuring permissions..."
if ! groups $USER | grep &>/dev/null 'docker'; then
    sudo groupadd docker 2>/dev/null || true
    sudo usermod -aG docker $USER
    echo "User added to docker group."
fi

# --- Part 3: Build Function ---
do_build() {
    echo "=== Starting Build Process ==="
    
    # 1. Build Docker Image
    echo "[+] Building Docker Build Image (btc3-legacy)..."
    docker build -t btc3-legacy -f Dockerfile.legacy .

    # 2. Run Compile
    echo "[+] Compiling binaries inside container..."
    # We map current dir to /btc5 inside container
    docker run --rm -v $(pwd):/btc5 -w /btc5 btc3-legacy /bin/bash -c "
        set -e
        echo '--- Building Dependencies (Depends System) ---'
        cd depends
        make HOST=x86_64-pc-linux-gnu NO_QT=1 -j\$(nproc)
        cd ..
        
        echo '--- Configuring CMake ---'
        rm -rf build-legacy
        cmake -B build-legacy -DCMAKE_TOOLCHAIN_FILE=depends/x86_64-pc-linux-gnu/toolchain.cmake
        
        echo '--- Compiling bitmintid and bitminti-cli ---'
        cmake --build build-legacy -j\$(nproc) --target bitmintid bitminti-cli
    "
    
    echo "=== SUCCESS ==="
    echo "Legacy binaries are located in: build-legacy/src/"
    ls -lh build-legacy/src/bitmintid build-legacy/src/bitminti-cli
}

# --- Part 4: Execution ---
# Check if we have docker access directly
if docker ps >/dev/null 2>&1; then
    do_build
else
    echo "[!] Current user cannot verify permissions instantly."
    echo "[*] Attempting to run build with 'sg' (subgroup) command..."
    # Execute the function within the docker group context
    # We export the function to be available in bash -c
    export -f do_build
    sg docker -c "bash -c do_build"
fi
