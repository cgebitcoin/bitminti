#!/bin/bash

# Script to Clone, Patch, and Build XMRig for BitMinti (Bitcoin Header support)
# Usage: ./build_custom_xmrig.sh

echo "[*] Installing XMRig Dependencies..."
sudo apt-get update
sudo apt-get install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

echo "[*] Initializing XMRig Submodule..."
git submodule update --init --recursive

if [ ! -d "xmrig" ]; then
    echo "[-] Error: xmrig directory not found."
    exit 1
fi

cd xmrig

echo "[*] Building XMRig (from submodule)..."
# Clean previous build if needed
if [ -d "build" ]; then
    rm -rf build
fi
mkdir build
cd build
# Disable TLS since we are mining locally and OpenSSL is finicky.
cmake .. -DXMRIG_DEPS=OFF -DWITH_TLS=OFF
make -j$(nproc)

echo "[+] Build Complete!"
echo "    Run with: ./xmrig -o 127.0.0.1:3333 -u admin --algo=rx/0 --randomx-mode=light --no-dmi"
exit 0
# We want to see the BLOB being hashed.
# Target: src/backend/cpu/CpuBackend.cpp
# Look for: rx_calculate_hash(
# Insert print logic before it.

BACKEND_FILE="src/backend/cpu/CpuBackend.cpp"
if [ -f "$BACKEND_FILE" ]; then
    # Create backup
    cp $BACKEND_FILE "$BACKEND_FILE.bak"
    
    # We use sed to append lines after "rx_calculate_hash" is found? No, BEFORE.
    # It's safer to find the function call and insert before it.
    # Pattern: "rx_calculate_hash(job->dataset(),"
    
    # Debug Code to Insert:
    # printf("XMRIG_DEBUG_BLOB: "); for(int i=0;i<job->size();i++) printf("%02x", ((uint8_t*)job->blob())[i]); printf("\n");
    
    # Insert at the beginning of the hashing work loop or just usage.
    # Actually, simpler: src/crypto/rx/RxAlgo.cpp might be easier to patch if it wraps.
    # But CpuBackend is where the job is prepared.
    
    # Let's try injecting into src/base/net/stratum/Job.cpp inside "Job::nonce()" or similar?
    # No, we want the final blob passed to RandomX.
    
    # Find the file containing "rx_calculate_hash"
    # It might be in RxAlgo.cpp, Rx.cpp, or headers.
    
    TARGET_RX_FILE=$(grep -r "rx_calculate_hash" src/crypto/rx | cut -d: -f1 | head -n 1)
    
    if [ -z "$TARGET_RX_FILE" ]; then
        # Try broader search
        TARGET_RX_FILE=$(grep -r "rx_calculate_hash" src | grep ".cpp" | cut -d: -f1 | head -n 1)
    fi
    
    if [ -n "$TARGET_RX_FILE" ]; then
        echo "[*] Found Hashing Function in: $TARGET_RX_FILE"
        RX_ALGO_FILE="$TARGET_RX_FILE"
        
        # DEBUG: Print the line we are trying to match
        echo "DEBUG: Content around target:"
        grep -C 2 "rx_calculate_hash" $RX_ALGO_FILE
        
        # Add headers for printf
        sed -i '1i #include <stdio.h>' $RX_ALGO_FILE
        
        DBG_CMD='printf("XMRIG_HASH_DEBUG: "); const uint8_t* p = (const uint8_t*)input; for(size_t i=0; i<size; i++) printf("%02x", p[i]); printf("\\n");'

        # Use -z for multiline? No.
        # Just match the string "rx_calculate_hash"
        # We use slash / delimiter to likely avoid pipe conflict? Or pipe | is fine.
        
        if sed -i "s|rx_calculate_hash|${DBG_CMD} rx_calculate_hash|g" $RX_ALGO_FILE; then
             echo "sed command executed."
        fi
        
        # Verify
        if grep -q "XMRIG_HASH_DEBUG" $RX_ALGO_FILE; then
            echo "[+] PATCH VERIFIED: Debug code found."
        else
            echo "[-] PATCH FAILED: Debug code NOT found."
        fi
    else
        echo "[-] Could not find any file containing rx_calculate_hash"
    fi
else
    echo "[-] Could not find CpuBackend.cpp"
fi

echo "[*] Building XMRig..."
mkdir build
cd build
cmake ..
make -j$(nproc)

echo "[+] Build Complete!"
echo "    Run with: ./xmrig -o 127.0.0.1:3333 -u admin --algo=rx/0 --randomx-mode=light"
