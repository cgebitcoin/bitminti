# BitMinti RPC Command Reference

This guide covers the most commonly used RPC commands for interacting with your BitMinti node.

## Connection Format

Default RPC Port: **13336**

All commands use this format:

```bash
./bin/bitminti-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin <COMMAND> [PARAMS...]
```

For brevity, examples below use `bitminti-cli` as shorthand.

## Wallet Commands

### Create a Wallet

```bash
bitminti-cli createwallet "wallet_name"
```

**Example**:
```bash
bitminti-cli createwallet "miner"
# Output: {"name": "miner", "warning": ""}
```

### Load a Wallet

```bash
bitminti-cli loadwallet "wallet_name"
```

### List Wallets

```bash
bitminti-cli listwallets
# Output: ["miner", "savings"]
```

### Get New Address

```bash
bitminti-cli getnewaddress "label"
```

**Example**:
```bash
bitminti-cli getnewaddress "mining"
# Output: btc31qegfazu3879ywqch9pk9z92azr7sddflaskzry4
```

### Get Balance

```bash
# Total balance (all labels)
bitminti-cli getbalance "*"

# Specific label
bitminti-cli getbalance "mining"
```

### List Unspent Outputs (UTXOs)

```bash
bitminti-cli listunspent [minconf] [maxconf]
```

**Examples**:
```bash
# All confirmed UTXOs
bitminti-cli listunspent

# Include unconfirmed
bitminti-cli listunspent 0

# Only immature coinbase (< 100 confirmations)
bitminti-cli listunspent 0 99
```

### Send Coins

```bash
bitminti-cli sendtoaddress "address" amount
```

**Example**:
```bash
bitminti-cli sendtoaddress "btc31qjnxf60l7rvrs72p45u8gg5e33vxxt6rt6scp27" 10.5
# Output: <transaction_id>
```

### List Transactions

```bash
bitminti-cli listtransactions "*" [count] [skip]
```

**Example**:
```bash
# Last 20 transactions
bitminti-cli listtransactions "*" 20
```

### Get Transaction Details

```bash
bitminti-cli gettransaction "txid"
```

### Backup Wallet

```bash
bitminti-cli backupwallet "/path/to/backup.dat"
```

### Dump Private Key

```bash
bitminti-cli dumpprivkey "address"
```

**⚠️ Warning**: Keep private keys secure!

### Import Private Key

```bash
bitminti-cli importprivkey "private_key_wif" "label" [rescan]
```

## Mining Commands

### Generate Blocks

```bash
bitminti-cli generatetoaddress nblocks "address"
```

**Example**:
```bash
# Mine 10 blocks
bitminti-cli generatetoaddress 10 "btc31qegfazu3879ywqch9pk9z92azr7sddflaskzry4"
```

### Get Mining Info

```bash
bitminti-cli getmininginfo
```

## Blockchain Commands

### Get Block Count

```bash
bitminti-cli getblockcount
# Output: 1523
```

### Get Blockchain Info

```bash
bitminti-cli getblockchaininfo
```

**Output includes**:
- `chain`: Network name
- `blocks`: Current height
- `headers`: Known headers
- `difficulty`: Current difficulty
- `verificationprogress`: Sync progress (1.0 = fully synced)

### Get Block Hash

```bash
bitminti-cli getblockhash height
```

**Example**:
```bash
bitminti-cli getblockhash 100
# Output: 624d60ba58fe61f9d85f91f422948b6accc572bb265ce6860581bdaaf9304444
```

### Get Block

```bash
bitminti-cli getblock "blockhash" [verbosity]
```

**Verbosity levels**:
- `0`: Hex-encoded data
- `1`: JSON object (default)
- `2`: JSON with transaction details

**Example**:
```bash
bitminti-cli getblock "624d60ba58fe61f9d85f91f422948b6accc572bb265ce6860581bdaaf9304444" 1
```

### Get Best Block Hash

```bash
bitminti-cli getbestblockhash
```

## Network Commands

### Get Connection Count

```bash
bitminti-cli getconnectioncount
# Output: 3
```

### Get Peer Info

```bash
bitminti-cli getpeerinfo
```

**Useful fields**:
- `addr`: Peer address
- `version`: Protocol version
- `subver`: Client version
- `inbound`: Connection direction
- `bytessent`/`bytesrecv`: Traffic stats

### Add Node

```bash
bitminti-cli addnode "ip:port" "add|remove|onetry"
```

**Examples**:
```bash
# Add permanent peer
bitminti-cli addnode "192.168.1.100:13337" "add"

# Remove peer
bitminti-cli addnode "192.168.1.100:13337" "remove"

# Try connecting once
bitminti-cli addnode "192.168.1.100:13337" "onetry"
```

### Get Network Info

```bash
bitminti-cli getnetworkinfo
```

### Get Added Node Info

```bash
bitminti-cli getaddednodeinfo
```

## Mempool Commands

### Get Mempool Info

```bash
bitminti-cli getmempoolinfo
```

**Output includes**:
- `size`: Number of transactions
- `bytes`: Total size
- `usage`: Memory usage
- `mempoolminfee`: Minimum fee rate

### Get Raw Mempool

```bash
bitminti-cli getrawmempool [verbose]
```

**Example**:
```bash
# List transaction IDs
bitminti-cli getrawmempool false

# Detailed info
bitminti-cli getrawmempool true
```

## Transaction Commands

### Get Raw Transaction

```bash
bitminti-cli getrawtransaction "txid" [verbose]
```

**Example**:
```bash
# Hex format
bitminti-cli getrawtransaction "08b915caef7164260055aed2d3fd84ca72234a03b8588a9a8c1a577ab854c6e1"

# JSON format
bitminti-cli getrawtransaction "08b915caef7164260055aed2d3fd84ca72234a03b8588a9a8c1a577ab854c6e1" true
```

### Decode Raw Transaction

```bash
bitminti-cli decoderawtransaction "hex"
```

### Send Raw Transaction

```bash
bitminti-cli sendrawtransaction "hex"
```

## Utility Commands

### Validate Address

```bash
bitminti-cli validateaddress "address"
```

**Example**:
```bash
bitminti-cli validateaddress "btc31qegfazu3879ywqch9pk9z92azr7sddflaskzry4"
```

**Output includes**:
- `isvalid`: true/false
- `address`: Normalized address
- `scriptPubKey`: Script
- `isscript`: Is script address
- `iswitness`: Is witness address

### Get Descriptor Info

```bash
bitminti-cli getdescriptorinfo "descriptor"
```

### Estimate Smart Fee

```bash
bitminti-cli estimatesmartfee conf_target
```

**Example**:
```bash
bitminti-cli estimatesmartfee 6
```

## Control Commands

### Get Info

```bash
bitminti-cli getinfo
```

**Deprecated** – Use specific commands instead:
- `getblockchaininfo`
- `getnetworkinfo`
- `getwalletinfo`

### Stop Daemon

```bash
bitminti-cli stop
```

### Uptime

```bash
bitminti-cli uptime
# Output: 86400 (seconds)
```

## Advanced Commands

### Rescan Blockchain

```bash
bitminti-cli rescanblockchain [start_height] [stop_height]
```

**Example**:
```bash
# Rescan from block 100 to tip
bitminti-cli rescanblockchain 100
```

### Scan UTXO Set

```bash
bitminti-cli scantxoutset "start" ["descriptor",...]
```

**Example**:
```bash
# Find all UTXOs for an address
bitminti-cli scantxoutset "start" "[\"addr(btc31qjnxf60l7rvrs72p45u8gg5e33vxxt6rt6scp27)\"]"
```

### Get Chain Tips

```bash
bitminti-cli getchaintips
```

Shows all known chain tips (useful for detecting forks).

## Batch Commands

You can batch multiple commands in one RPC call:

```bash
bitminti-cli batch '[
  {"method": "getblockcount"},
  {"method": "getbalance", "params": ["*"]},
  {"method": "getconnectioncount"}
]'
```

## Common Workflows

### Check Node Status

```bash
#!/bin/bash
echo "Block Height: $(bitminti-cli getblockcount)"
echo "Connections: $(bitminti-cli getconnectioncount)"
echo "Balance: $(bitminti-cli getbalance '*') BitMinti"
echo "Mempool: $(bitminti-cli getmempoolinfo | jq -r '.size') transactions"
```

### Monitor Mining Progress

```bash
#!/bin/bash
while true; do
  HEIGHT=$(bitminti-cli getblockcount)
  BALANCE=$(bitminti-cli getbalance "*")
  echo "[$(date)] Height: $HEIGHT | Balance: $BALANCE BitMinti"
  sleep 10
done
```

### Send with Confirmation

```bash
#!/bin/bash
ADDR="btc31qjnxf60l7rvrs72p45u8gg5e33vxxt6rt6scp27"
AMOUNT=10.0

# Send transaction
TXID=$(bitminti-cli sendtoaddress "$ADDR" $AMOUNT)
echo "Transaction sent: $TXID"

# Mine a block to confirm
MINING_ADDR=$(bitminti-cli getnewaddress)
bitminti-cli generatetoaddress 1 "$MINING_ADDR"

# Verify confirmation
CONFIRMATIONS=$(bitminti-cli gettransaction "$TXID" | jq -r '.confirmations')
echo "Confirmations: $CONFIRMATIONS"
```

## Help Commands

### List All Commands

```bash
bitminti-cli help
```

### Get Help for Specific Command

```bash
bitminti-cli help <command>
```

**Example**:
```bash
bitminti-cli help sendtoaddress
```

## Tips

1. **Use jq for JSON parsing**: `bitminti-cli getblockchaininfo | jq '.blocks'`
2. **Save common commands as aliases**: `alias btc3='bitminti-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin'`
3. **Check command syntax**: Always use `bitminti-cli help <command>` if unsure
4. **Batch operations**: Use shell loops for repetitive tasks
5. **Monitor logs**: Check `btc3-data/debug.log` for detailed information

## Next Steps

- [Start mining](MINING.md) to earn BitMinti
- [Join the network](JOINING.md) to connect with other nodes
- Explore advanced RPC features in Bitcoin Core documentation

