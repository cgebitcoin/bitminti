#!/bin/bash
# BitMinti Continuous Miner for macOS
# This script will keep mining to your local wallet automatically.

# Automatically find the build directory
BUILD_DIR="./build"
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: build directory not found. Please run this from the project root."
    exit 1
fi

ADDR="btc31qjlez8j87lz0q8p2hnhy2rp2jvqkes7efn0v97p"
DATADIR="$BUILD_DIR/btc3_data"
CLI="$BUILD_DIR/bin/bitminti-cli -datadir=$DATADIR"

# Number of parallel mining processes (use all logical CPUs)
THREADS=$(sysctl -n hw.logicalcpu)

echo "--------------------------------------------------"
echo "🚀 BitMinti Multi-Threaded Mining Started ($THREADS threads)"
echo "Target Address: $ADDR"
echo "Press [Ctrl+C] to stop all threads."
echo "--------------------------------------------------"

# Function to mine in a loop
mine_worker() {
    local id=$1
    while true; do
        echo "[Thread $id] ⛏️ Mining..."
        # Use a large max_tries to keep the RPC call busy
        $CLI generatetoaddress 1 $ADDR 1000000 > /dev/null 2>&1
        
        # Check if any thread found a block
        HEIGHT=$($CLI getblockcount)
        echo "[Thread $id] Network Height: $HEIGHT"
    done
}

# Launch workers
for ((i=1; i<=THREADS; i++)); do
    mine_worker $i &
done

# Wait for all background processes
wait
