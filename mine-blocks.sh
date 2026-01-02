#!/bin/bash
# BitMinti Mining Script
# Usage: ./mine-blocks.sh [number_of_blocks]

BLOCKS=${1:-10}
BUILD_DIR="$(cd "$(dirname "$0")" && pwd)/build/bin"
DATADIR="${DATADIR:-$HOME/.bitminti}"
AUTH="${BitMinti_AUTH:--rpcuser=test -rpcpassword=test}"

echo "=== BitMinti Mining Script ==="
echo "Target blocks: $BLOCKS"
echo ""

# Check if daemon is running
if ! pgrep -fl bitmintid > /dev/null; then
    echo "Starting bitmintid daemon..."
    $BUILD_DIR/bitmintid -datadir="$DATADIR" -addnode=3.146.187.209:13337 -daemon -miningfastmode=1
    sleep 10
fi

# Verify daemon is responsive
if ! $BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH getblockcount &>/dev/null; then
    echo "ERROR: Daemon not responding."
    echo "Try running ./start-node.sh first"
    exit 1
fi

# Get or create mining address
# First try to load the wallet, ignore error if it creates a duplicate load error
$BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH loadwallet "miner" >/dev/null 2>&1

ADDR=$($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH getnewaddress 2>/dev/null)
if [ -z "$ADDR" ]; then
    echo "Creating wallet..."
    $BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH createwallet "miner" >/dev/null 2>&1
    ADDR=$($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH getnewaddress)
fi

echo "Mining address: $ADDR"
echo "Starting height: $($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH getblockcount)"
echo ""

# Mine blocks
# Mine blocks with chunking to prevent RPC timeouts
for i in $(seq 1 $BLOCKS); do
    echo -n "Mining block $i/$BLOCKS"
    
    while true; do
        # Try 10000 hashes at a time (keep RPC responsive)
        RESULT=$($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH generatetoaddress 1 "$ADDR" 10000 2>&1)
        
        # Check if we found a block (result is a JSON array with a hash)
        if [[ "$RESULT" == *"["* && "$RESULT" != "[]" ]]; then
            HEIGHT=$($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH getblockcount)
            echo " ✓ (height: $HEIGHT)"
            break
        elif [[ "$RESULT" == "[]" ]]; then
            # No block found in this chunk, retry
            echo -n "."
        else
            # Error occurred
            echo " ✗ FAILED"
            echo "Error: $RESULT"
            echo "Check logs: tail $DATADIR/debug.log"
            exit 1
        fi
    done
done

echo ""
echo "=== Mining Complete ==="
echo "Final height: $($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH getblockcount)"
echo "Balance: $($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH getbalance) BitMinti"
