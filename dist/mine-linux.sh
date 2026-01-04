#!/bin/bash
# BitMinti One-Click Miner for Linux
# This script will automatically start mining BitMinti

set -e

echo "========================================"
echo "   BitMinti One-Click Miner"
echo "   CPU Mining for Everyone"
echo "========================================"
echo ""

# Set variables
DATADIR="${HOME}/.bitminti"
WALLET_NAME="miner"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/build/bin"

# Check if binaries exist
if [ ! -f "${BIN_DIR}/bitmintid" ]; then
    echo "ERROR: bitmintid not found!"
    echo ""
    echo "Looking for: ${BIN_DIR}/bitmintid"
    echo ""
    echo "Please build BitMinti first:"
    echo "  cmake -B build -DBUILD_GUI=OFF"
    echo "  cmake --build build -j\$(nproc)"
    echo ""
    echo "Or download pre-built binaries from:"
    echo "https://github.com/cgebitcoin/bitminti/releases"
    exit 1
fi

# Create data directory
mkdir -p "${DATADIR}"

echo "Starting BitMinti daemon..."
echo "Data directory: ${DATADIR}"
echo ""

# Check if daemon is already running
if pgrep -x bitmintid > /dev/null; then
    echo "Daemon already running."
else
    "${BIN_DIR}/bitmintid" -datadir="${DATADIR}" -daemon -miningfastmode=1
    echo "Waiting for daemon to initialize..."
    sleep 10
fi

# Create/load wallet
echo "Setting up mining wallet..."
"${BIN_DIR}/bitminti-cli" -datadir="${DATADIR}" createwallet "${WALLET_NAME}" >/dev/null 2>&1 || \
"${BIN_DIR}/bitminti-cli" -datadir="${DATADIR}" loadwallet "${WALLET_NAME}" >/dev/null 2>&1

# Get mining address
MINING_ADDR=$("${BIN_DIR}/bitminti-cli" -datadir="${DATADIR}" -rpcwallet="${WALLET_NAME}" getnewaddress "" "bech32" 2>/dev/null)

if [ -z "$MINING_ADDR" ]; then
    echo "ERROR: Could not generate mining address!"
    exit 1
fi

echo ""
echo "========================================"
echo "Mining address: ${MINING_ADDR}"
echo "========================================"
echo ""
echo "Mining will start now. Press Ctrl+C to stop."
echo ""

# Trap Ctrl+C to allow graceful shutdown
trap "echo ''; echo 'Mining stopped by user.'; exit 0" INT

# Start continuous mining loop
while true; do
    if ! "${BIN_DIR}/bitminti-cli" -datadir="${DATADIR}" -rpcwallet="${WALLET_NAME}" generatetoaddress 1 "${MINING_ADDR}" 1000000 2>&1; then
        echo "Mining command failed. Retrying in 5 seconds..."
        sleep 5
    fi
done
