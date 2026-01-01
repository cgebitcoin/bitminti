#!/bin/bash
# Start BTC3 Node (Safe Mode)

# Check for Root (Required for Fast Mode huge pages/memlock)
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: You must run this script with sudo!"
  echo "Usage: sudo ./start-node.sh"
  exit 1
fi

# Data directory
# User confirmed working path: /root/.btc3
DATADIR="/root/.btc3"
echo "Running as Root. Data Directory: $DATADIR"


# Create datadir if missing
mkdir -p "$DATADIR"

# Create config if missing
if [ ! -f "$DATADIR/bitcoin.conf" ]; then
    echo "Creating default config..."
    echo -e "server=1\nrpcport=8332\nminingfastmode=1" > "$DATADIR/bitcoin.conf"
fi

# Stop existing
pkill btc3d
sleep 2

# Start daemon
# Configure Huge Pages (Linux Only) - Required for RandomX Fast Mode
if [[ "$(uname)" == "Linux" ]]; then
    CURRENT_HP=$(sysctl -n vm.nr_hugepages 2>/dev/null || echo 0)
    if [ "$CURRENT_HP" -lt 1280 ]; then
        echo "Huge Pages low ($CURRENT_HP). Attempting to increase to 3000..."
        # Try to set it (will ask for sudo password if needed)
        sudo sysctl -w vm.nr_hugepages=3000 || echo "WARNING: Failed to set huge pages. Run 'sudo sysctl -w vm.nr_hugepages=3000' manually for fast mining."
    else
        echo "Huge Pages OK ($CURRENT_HP)."
    fi
fi

# Scan for core count (Linux: nproc, Mac: sysctl)
DETECTED_CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
CORES=$(echo "$DETECTED_CORES" | tr -dc '0-9')
if [ -z "$CORES" ]; then CORES=4; fi

echo "Starting BTC3 daemon (Cores: $CORES)..."
echo "Running in FOREGROUND (Exact match to manual command)"
echo "Do NOT close this terminal!"

# Set limits explicitly
ulimit -l unlimited

# EXACT MATCH to your manual command:
# ./btc3d -datadir=/root/.btc3/ -miningfastmode=1 -dbcache=2048 -par=16 -addnode=3.146.187.209:13337 -printtoconsole
exec ./build/bin/btc3d -datadir="$DATADIR" -miningfastmode=1 -dbcache=2048 -par=$CORES -addnode=3.146.187.209:13337 printtoconsole
