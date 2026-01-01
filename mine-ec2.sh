#!/bin/bash
# Optimized Miner for AWS EC2 (c5.4xlarge)
# Uses btc3-cli with EXPLICIT cookie path

# Dynamically detect threads
DETECTED_THREADS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
THREADS=$(echo "$DETECTED_THREADS" | tr -dc '0-9')
if [ -z "$THREADS" ] || [ "$THREADS" -lt 2 ]; then THREADS=4; fi

# Default Data Directory (Proven working path)
DATADIR="/root/.btc3"

# Fallback check (Just in case, but prioritize the proven one)
if [ ! -d "$DATADIR" ] && [ -d "/root/.bitcoin" ]; then
    DATADIR="/root/.bitcoin"
fi

COOKIE_FILE="$DATADIR/.cookie"
echo "Targeting Data Directory: $DATADIR"
echo "Targeting Cookie File:    $COOKIE_FILE"

# 1. WAIT for Cookie logic
MAX_RETRIES=30
COUNT=0
echo "Waiting for cookie file..."
while [ ! -f "$COOKIE_FILE" ]; do
    sleep 2
    echo -n "."
    COUNT=$((COUNT+1))
    if [ "$COUNT" -gt "$MAX_RETRIES" ]; then
        echo ""
        echo "ERROR: Cookie file NOT found at: $COOKIE_FILE"
        echo "Is the daemon running? (sudo ./start-node.sh)"
        exit 1
    fi
done
echo ""
echo "Cookie found!"

# 2. RUN CLI Wrapper
# Explicitly pass -rpccookiefile to avoid any guessing
run_cli() {
    if sudo test -w "$DATADIR"; then PREFIX=""; else PREFIX="sudo"; fi
    $PREFIX ./build/bin/btc3-cli -datadir="$DATADIR" -rpccookiefile="$COOKIE_FILE" "$@"
}

# 3. Get Address
get_address() {
    run_cli createwallet "miner" >/dev/null 2>&1 || true
    run_cli loadwallet "miner" >/dev/null 2>&1 || true
    run_cli getnewaddress
}

ADDR=$(get_address)
ADDR=$(echo "$ADDR" | tr -d '\r')

echo "=== BTC3 CLI MINER ==="
echo "Address: $ADDR"

if [ -z "$ADDR" ] || [[ "$ADDR" == *"error"* ]]; then
    echo "ERROR: Failed to get address."
    # Verbose debug
    run_cli getblockchaininfo
    exit 1
fi

echo "Threads: $THREADS"
echo "----------------------"

while true; do
    echo "Mining chunk (10M hashes)..."
    START=$(date +%s)
    # native generate (nblocks, address, maxtries, nthreads)
    run_cli generatetoaddress 1 "$ADDR" 10000000 "$THREADS"
    END=$(date +%s)
    DIFF=$((END - START))
    echo "Time: ${DIFF}s"
    echo ""
    sleep 1
done
