# Mining BTC3

BTC3 uses a trivial proof-of-work difficulty, making it instantly mineable on any modern CPU. This guide covers everything from basic mining to automated strategies.

## Quick Start Mining

### 1. Start the Daemon

```bash
./bin/btc3d -datadir=./btc3-data -server -rpcuser=admin -rpcpassword=admin -fallbackfee=0.00001 -daemon
```

### 2. Create or Load a Wallet

```bash
# Create a new wallet
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin createwallet "miner"

# Or load an existing wallet
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin loadwallet "miner"
```

### 3. Generate a Mining Address

```bash
MINING_ADDR=$(./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getnewaddress "mining")
echo "Your mining address: $MINING_ADDR"
```

### 4. Mine Blocks

```bash
# Mine a single block
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin generatetoaddress 1 $MINING_ADDR

# Mine 101 blocks (100 to mature + 1 to spend)
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin generatetoaddress 101 $MINING_ADDR
```

### 5. Check Your Balance

```bash
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getbalance "*"
```

## Understanding Coinbase Maturity

Newly mined coins require **100 confirmations** before they can be spent. This means:
- Mine block 1 → reward available at block 101
- Mine block 2 → reward available at block 102
- etc.

**Best practice**: Mine 101 blocks initially to have immediately spendable coins.

## Automated Mining

### Continuous Mining Script

Create a file `mine.sh`:

```bash
#!/usr/bin/env bash

DATADIR=./btc3-data
RPCUSER=admin
RPCPASS=admin
CLI="./bin/btc3-cli -datadir=$DATADIR -rpcuser=$RPCUSER -rpcpassword=$RPCPASS"

# Get or create mining address
MINING_ADDR=$($CLI getnewaddress "mining" 2>/dev/null || $CLI getnewaddress)

echo "Mining to address: $MINING_ADDR"
echo "Press Ctrl+C to stop"

while true; do
    # Mine one block
    BLOCK_HASH=$($CLI generatetoaddress 1 $MINING_ADDR | jq -r '.[0]')
    
    # Get current height
    HEIGHT=$($CLI getblockcount)
    
    # Get balance
    BALANCE=$($CLI getbalance "*")
    
    echo "[Block $HEIGHT] Hash: $BLOCK_HASH | Balance: $BALANCE BTC3"
    
    # Optional: add delay (remove for maximum speed)
    # sleep 1
done
```

Make it executable and run:

```bash
chmod +x mine.sh
./mine.sh
```

### Mining with Target Block Count

Create `mine-target.sh`:

```bash
#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_blocks>"
    exit 1
fi

TARGET=$1
DATADIR=./btc3-data
RPCUSER=admin
RPCPASS=admin
CLI="./bin/btc3-cli -datadir=$DATADIR -rpcuser=$RPCUSER -rpcpassword=$RPCPASS"

MINING_ADDR=$($CLI getnewaddress "mining" 2>/dev/null || $CLI getnewaddress)

echo "Mining $TARGET blocks to $MINING_ADDR"

for ((i=1; i<=TARGET; i++)); do
    $CLI generatetoaddress 1 $MINING_ADDR > /dev/null
    HEIGHT=$($CLI getblockcount)
    echo "Mined block $i/$TARGET (height: $HEIGHT)"
done

BALANCE=$($CLI getbalance "*")
echo "Mining complete! Balance: $BALANCE BTC3"
```

Usage:

```bash
chmod +x mine-target.sh
./mine-target.sh 1000  # Mine 1000 blocks
```

## Mining Statistics

### Check Mining Progress

```bash
# Current block height
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getblockcount

# Get blockchain info
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getblockchaininfo

# List recent blocks
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin listsinceblock
```

### View Mining Rewards

```bash
# List all transactions (including mining rewards)
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin listtransactions "*" 100

# List only immature rewards
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin listunspent 0 99
```

## Advanced Mining

### Mining to Multiple Addresses

```bash
# Create multiple addresses
ADDR1=$(./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getnewaddress "pool1")
ADDR2=$(./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getnewaddress "pool2")

# Alternate between them
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin generatetoaddress 10 $ADDR1
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin generatetoaddress 10 $ADDR2
```

### Mining with Transaction Inclusion

```bash
# Send a transaction
TXID=$(./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin sendtoaddress <ADDRESS> 10.0)

# Mine a block to confirm it
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin generatetoaddress 1 $MINING_ADDR

# Verify transaction is confirmed
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin gettransaction $TXID
```

## Systemd Service (Linux)

For continuous mining on a server, create `/etc/systemd/system/btc3-miner.service`:

```ini
[Unit]
Description=BTC3 Continuous Miner
After=btc3d.service
Requires=btc3d.service

[Service]
Type=simple
User=btc3
WorkingDirectory=/home/btc3/btc3
ExecStart=/home/btc3/btc3/mine.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable btc3-miner
sudo systemctl start btc3-miner
sudo systemctl status btc3-miner
```

## Troubleshooting

### "Method not found" Error

**Problem**: RPC server not responding  
**Solution**: Ensure daemon is running with `-server` flag

### "Wallet not found"

**Problem**: Wallet not loaded  
**Solution**: Load wallet first:
```bash
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin loadwallet "miner"
```

### Balance Shows 0 After Mining

**Problem**: Coinbase rewards not yet mature  
**Solution**: Mine 100 more blocks to mature the first reward

### "Could not connect to server"

**Problem**: Daemon not running  
**Solution**: Start daemon:
```bash
./bin/btc3d -datadir=./btc3-data -daemon
```

## Mining Best Practices

1. **Initial Setup**: Mine 101 blocks to have immediately spendable coins
2. **Regular Mining**: Mine continuously or in batches as needed
3. **Backup Wallet**: Regularly backup `btc3-data/wallets/miner/wallet.dat`
4. **Monitor Balance**: Check balance periodically to track rewards
5. **Network Participation**: Keep daemon running to help secure the network

## Next Steps

- [Join the network](JOINING.md) to mine alongside others
- [Use RPC commands](RPC.md) to interact with your node
- Share your mining address to receive coins from others

