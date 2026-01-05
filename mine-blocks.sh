#!/bin/bash
# BitMinti Mining Script with Performance Timer

# 1. Setup Variables
BLOCKS=${1:-10}
BUILD_DIR="$(cd "$(dirname "$0")" && pwd)/build/bin"
DATADIR="${DATADIR:-$HOME/.btc3}"
AUTH="${BitMinti_AUTH:-}"
WALLET_NAME="miner"

echo "=== BitMinti Mining Script ==="
echo "Target blocks: $BLOCKS"
echo "----------------------------------------"

# 2. Start Daemon if not running
# 2. Start Daemon if not running
mkdir -p "$DATADIR"

if ! pgrep -x bitmintid > /dev/null; then
    echo "Starting bitmintid daemon..."
    $BUILD_DIR/bitmintid -datadir="$DATADIR" -daemon -miningfastmode=1
    echo "Waiting for daemon to initialize..."
else
    echo "Daemon already running."
fi

# Wait for cookie file
COOKIE_FILE="$DATADIR/.cookie"
MAX_RETRIES=30
COUNT=0

while [ ! -f "$COOKIE_FILE" ]; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "Error: Timed out waiting for RPC cookie file at $COOKIE_FILE"
        echo "Check debug.log in $DATADIR for errors."
        exit 1
    fi
    echo "Waiting for RPC cookie... ($COUNT/$MAX_RETRIES)"
    sleep 1
    ((COUNT++))
done

echo "Daemon RPC is ready."

# 3. Ensure Wallet is Loaded & Address is Valid
$BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH loadwallet "$WALLET_NAME" >/dev/null 2>&1

ADDR=$($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH -rpcwallet="$WALLET_NAME" getnewaddress "" "bech32" 2>/dev/null)

if [ -z "$ADDR" ] || [[ "$ADDR" == *"error"* ]]; then
    echo "Creating/Opening wallet: $WALLET_NAME..."
    $BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH createwallet "$WALLET_NAME" >/dev/null 2>&1
    sleep 2
    ADDR=$($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH -rpcwallet="$WALLET_NAME" getnewaddress "" "bech32")
fi

if [ -z "$ADDR" ]; then
    echo " ✗ FATAL ERROR: Could not generate mining address."
    exit 1
fi

echo "Mining address: $ADDR"
echo "Starting height: $($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH getblockcount)"
echo "----------------------------------------"

# 4. Mining Loop
for i in $(seq 1 $BLOCKS); do
    START_TIME=$(date +%s)
    echo -n "[$i/$BLOCKS] Mining... "

    while true; do
        # 100k tries per call
        RESULT=$($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH -rpcwallet="$WALLET_NAME" generatetoaddress 1 "$ADDR" 10000 2>&1)
        
        CLEAN_RESULT=$(echo "$RESULT" | tr -d '[:space:]')

        if [[ "$CLEAN_RESULT" != "[]" && "$CLEAN_RESULT" == \[* ]]; then
            END_TIME=$(date +%s)
            DURATION=$((END_TIME - START_TIME))
            HEIGHT=$($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH getblockcount)
            
            echo " ✓ FOUND! Height: $HEIGHT (Time: ${DURATION}s)"
            break 
        elif [[ "$CLEAN_RESULT" == "[]" ]]; then
            echo -n "." 
        else
            echo ""
            echo " ✗ FAILED - RPC Error detected"
            echo "Detail: $RESULT"
            exit 1
        fi
    done
done

echo ""
echo "=== Mining Complete ==="
FINAL_BAL=$($BUILD_DIR/bitminti-cli -datadir="$DATADIR" $AUTH -rpcwallet="$WALLET_NAME" getbalance)
echo "Final Balance: $FINAL_BAL BTC3"
