#!/bin/bash

# BitMinti RandomX Debug Tool Builder for EC2
# This compiles the debug_rx tool needed by monminti.py to verify hashes.

echo "[*] checking for RandomX source..."
if [ ! -d "src/randomx" ]; then
    echo "Error: src/randomx directory not found. Please run this from the root of the btc5 repo."
    exit 1
fi

echo "[*] Building librandomx.a..."
mkdir -p src/randomx/build
cd src/randomx/build
cmake .. -DARCH=native
make -j$(nproc)
cd ../../..

echo "[*] Compiling debug_rx..."
if [ -f "src/randomx/build/librandomx.a" ]; then
    g++ -std=c++11 debug_rx.cpp src/randomx/build/librandomx.a -o debug_rx -I src/randomx/src
    
    if [ -f "./debug_rx" ]; then
        echo "[+] SUCCESS: debug_rx created."
        echo "[*] Testing..."
        ./debug_rx 0000000000000000000000000000000000000000000000000000000000000000 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    else
        echo "[-] Error: Compilation failed."
    fi
else
    echo "[-] Error: librandomx.a failed to build."
fi
