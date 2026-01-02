#!/bin/bash
echo "=== HARD RESET & MINE ==="

# 1. Brutal kill
echo "Killing all BitMinti processes..."
pkill -9 bitmintid || true
pkill -9 bitminti-cli || true
sleep 3

# 2. Check clear
if pgrep -fl bitmintid; then
    echo "ERROR: Failed to kill bitmintid"
    exit 1
fi

# 3. Setup Data Dir
DATADIR="$HOME/.bitminti"
mkdir -p "$DATADIR"
rm -f "$DATADIR/.cookie" # Remove old cookie to prevent confusion

# 4. Write Config
echo "Writing new config..."
cat > "$DATADIR/bitcoin.conf" <<EOF
server=1
rpcuser=test
rpcpassword=test
rpcport=8332
miningfastmode=1
EOF

# 5. Start Daemon
echo "Starting daemon..."
./build/bin/bitmintid -datadir="$DATADIR" -daemon

# 6. Wait loop
echo "Waiting for RPC (30s timeout)..."
for i in {1..30}; do
    if ./build/bin/bitminti-cli -datadir="$DATADIR" -rpcuser=test -rpcpassword=test getblockchaininfo >/dev/null 2>&1; then
        echo "Connected after $i seconds!"
        break
    fi
    echo -n "."
    sleep 1
done

# 7. Check if failed
if ! ./build/bin/bitminti-cli -datadir="$DATADIR" -rpcuser=test -rpcpassword=test getblockchaininfo >/dev/null 2>&1; then
    echo ""
    echo "FAILED to connect."
    echo "Log tail:"
    tail -n 10 "$DATADIR/debug.log"
    exit 1
fi

# 8. Mine
echo ""
echo "Creating wallet..."
./build/bin/bitminti-cli -datadir="$DATADIR" -rpcuser=test -rpcpassword=test createwallet "miner" >/dev/null 2>&1 || true

echo "Mining 10 blocks..."
ADDR=$(./build/bin/bitminti-cli -datadir="$DATADIR" -rpcuser=test -rpcpassword=test getnewaddress)
echo "Address: $ADDR"

for i in {1..10}; do
   ./build/bin/bitminti-cli -datadir="$DATADIR" -rpcuser=test -rpcpassword=test generatetoaddress 1 "$ADDR"
done

echo "Done! Balance:"
./build/bin/bitminti-cli -datadir="$DATADIR" -rpcuser=test -rpcpassword=test getbalance
