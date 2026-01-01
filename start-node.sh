#!/bin/bash
# Start BTC3 Node (Safe Mode)

# Data directory
DATADIR="$HOME/.btc3"

# Create datadir if missing
mkdir -p "$DATADIR"

# Create config if missing
if [ ! -f "$DATADIR/bitcoin.conf" ]; then
    echo "Creating default config..."
    echo -e "server=1\nrpcuser=test\nrpcpassword=test\nrpcport=8332\nminingfastmode=1" > "$DATADIR/bitcoin.conf"
fi

# Stop existing
pkill btc3d
sleep 2

# Start daemon
echo "Starting BTC3 daemon..."
./build/bin/btc3d -datadir="$DATADIR" -daemon

# Wait for start
echo "Waiting for initialization..."
sleep 10

# Check status
./build/bin/btc3-cli -datadir="$DATADIR" -rpcuser=test -rpcpassword=test getblockchaininfo
