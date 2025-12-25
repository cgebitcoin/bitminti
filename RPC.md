# BTC3 RPC Command Reference

This guide covers the most commonly used RPC commands for interacting with your BTC3 node.

## Connection Format

All commands use this format:

```bash
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin <COMMAND> [PARAMS...]
```

For brevity, examples below use `btc3-cli` as shorthand.

## Wallet Commands

### Create a Wallet

```bash
btc3-cli createwallet "wallet_name"
```

**Example**:
```bash
btc3-cli createwallet "miner"
# Output: {"name": "miner", "warning": ""}
```

### Load a Wallet

```bash
btc3-cli loadwallet "wallet_name"
```

### List Wallets

```bash
btc3-cli listwallets
# Output: ["miner", "savings"]
```

### Get New Address

```bash
btc3-cli getnewaddress "label"
```

**Example**:
```bash
btc3-cli getnewaddress "mining"
# Output: btc31qegfazu3879ywqch9pk9z92azr7sddflaskzry4
```

### Get Balance

```bash
# Total balance (all labels)
btc3-cli getbalance "*"

# Specific label
btc3-cli getbalance "mining"
```

### List Unspent Outputs (UTXOs)

```bash
btc3-cli listunspent [minconf] [maxconf]
```

**Examples**:
```bash
# All confirmed UTXOs
btc3-cli listunspent

# Include unconfirmed
btc3-cli listunspent 0

# Only immature coinbase (< 100 confirmations)
btc3-cli listunspent 0 99
```

### Send Coins

```bash
btc3-cli sendtoaddress "address" amount
```

**Example**:
```bash
btc3-cli sendtoaddress "btc31qjnxf60l7rvrs72p45u8gg5e33vxxt6rt6scp27" 10.5
# Output: <transaction_id>
```

### List Transactions

```bash
btc3-cli listtransactions "*" [count] [skip]
```

**Example**:
```bash
# Last 20 transactions
btc3-cli listtransactions "*" 20
```

### Get Transaction Details

```bash
btc3-cli gettransaction "txid"
```

### Backup Wallet

```bash
btc3-cli backupwallet "/path/to/backup.dat"
```

### Dump Private Key

```bash
btc3-cli dumpprivkey "address"
```

**⚠️ Warning**: Keep private keys secure!

### Import Private Key

```bash
btc3-cli importprivkey "private_key_wif" "label" [rescan]
```

## Mining Commands

### Generate Blocks

```bash
btc3-cli generatetoaddress nblocks "address"
```

**Example**:
```bash
# Mine 10 blocks
btc3-cli generatetoaddress 10 "btc31qegfazu3879ywqch9pk9z92azr7sddflaskzry4"
```

### Get Mining Info

```bash
btc3-cli getmininginfo
```

## Blockchain Commands

### Get Block Count

```bash
btc3-cli getblockcount
# Output: 1523
```

### Get Blockchain Info

```bash
btc3-cli getblockchaininfo
```

**Output includes**:
- `chain`: Network name
- `blocks`: Current height
- `headers`: Known headers
- `difficulty`: Current difficulty
- `verificationprogress`: Sync progress (1.0 = fully synced)

### Get Block Hash

```bash
btc3-cli getblockhash height
```

**Example**:
```bash
btc3-cli getblockhash 100
# Output: 624d60ba58fe61f9d85f91f422948b6accc572bb265ce6860581bdaaf9304444
```

### Get Block

```bash
btc3-cli getblock "blockhash" [verbosity]
```

**Verbosity levels**:
- `0`: Hex-encoded data
- `1`: JSON object (default)
- `2`: JSON with transaction details

**Example**:
```bash
btc3-cli getblock "624d60ba58fe61f9d85f91f422948b6accc572bb265ce6860581bdaaf9304444" 1
```

### Get Best Block Hash

```bash
btc3-cli getbestblockhash
```

## Network Commands

### Get Connection Count

```bash
btc3-cli getconnectioncount
# Output: 3
```

### Get Peer Info

```bash
btc3-cli getpeerinfo
```

**Useful fields**:
- `addr`: Peer address
- `version`: Protocol version
- `subver`: Client version
- `inbound`: Connection direction
- `bytessent`/`bytesrecv`: Traffic stats

### Add Node

```bash
btc3-cli addnode "ip:port" "add|remove|onetry"
```

**Examples**:
```bash
# Add permanent peer
btc3-cli addnode "192.168.1.100:13337" "add"

# Remove peer
btc3-cli addnode "192.168.1.100:13337" "remove"

# Try connecting once
btc3-cli addnode "192.168.1.100:13337" "onetry"
```

### Get Network Info

```bash
btc3-cli getnetworkinfo
```

### Get Added Node Info

```bash
btc3-cli getaddednodeinfo
```

## Mempool Commands

### Get Mempool Info

```bash
btc3-cli getmempoolinfo
```

**Output includes**:
- `size`: Number of transactions
- `bytes`: Total size
- `usage`: Memory usage
- `mempoolminfee`: Minimum fee rate

### Get Raw Mempool

```bash
btc3-cli getrawmempool [verbose]
```

**Example**:
```bash
# List transaction IDs
btc3-cli getrawmempool false

# Detailed info
btc3-cli getrawmempool true
```

## Transaction Commands

### Get Raw Transaction

```bash
btc3-cli getrawtransaction "txid" [verbose]
```

**Example**:
```bash
# Hex format
btc3-cli getrawtransaction "08b915caef7164260055aed2d3fd84ca72234a03b8588a9a8c1a577ab854c6e1"

# JSON format
btc3-cli getrawtransaction "08b915caef7164260055aed2d3fd84ca72234a03b8588a9a8c1a577ab854c6e1" true
```

### Decode Raw Transaction

```bash
btc3-cli decoderawtransaction "hex"
```

### Send Raw Transaction

```bash
btc3-cli sendrawtransaction "hex"
```

## Utility Commands

### Validate Address

```bash
btc3-cli validateaddress "address"
```

**Example**:
```bash
btc3-cli validateaddress "btc31qegfazu3879ywqch9pk9z92azr7sddflaskzry4"
```

**Output includes**:
- `isvalid`: true/false
- `address`: Normalized address
- `scriptPubKey`: Script
- `isscript`: Is script address
- `iswitness`: Is witness address

### Get Descriptor Info

```bash
btc3-cli getdescriptorinfo "descriptor"
```

### Estimate Smart Fee

```bash
btc3-cli estimatesmartfee conf_target
```

**Example**:
```bash
btc3-cli estimatesmartfee 6
```

## Control Commands

### Get Info

```bash
btc3-cli getinfo
```

**Deprecated** – Use specific commands instead:
- `getblockchaininfo`
- `getnetworkinfo`
- `getwalletinfo`

### Stop Daemon

```bash
btc3-cli stop
```

### Uptime

```bash
btc3-cli uptime
# Output: 86400 (seconds)
```

## Advanced Commands

### Rescan Blockchain

```bash
btc3-cli rescanblockchain [start_height] [stop_height]
```

**Example**:
```bash
# Rescan from block 100 to tip
btc3-cli rescanblockchain 100
```

### Scan UTXO Set

```bash
btc3-cli scantxoutset "start" ["descriptor",...]
```

**Example**:
```bash
# Find all UTXOs for an address
btc3-cli scantxoutset "start" "[\"addr(btc31qjnxf60l7rvrs72p45u8gg5e33vxxt6rt6scp27)\"]"
```

### Get Chain Tips

```bash
btc3-cli getchaintips
```

Shows all known chain tips (useful for detecting forks).

## Batch Commands

You can batch multiple commands in one RPC call:

```bash
btc3-cli batch '[
  {"method": "getblockcount"},
  {"method": "getbalance", "params": ["*"]},
  {"method": "getconnectioncount"}
]'
```

## Common Workflows

### Check Node Status

```bash
#!/bin/bash
echo "Block Height: $(btc3-cli getblockcount)"
echo "Connections: $(btc3-cli getconnectioncount)"
echo "Balance: $(btc3-cli getbalance '*') BTC3"
echo "Mempool: $(btc3-cli getmempoolinfo | jq -r '.size') transactions"
```

### Monitor Mining Progress

```bash
#!/bin/bash
while true; do
  HEIGHT=$(btc3-cli getblockcount)
  BALANCE=$(btc3-cli getbalance "*")
  echo "[$(date)] Height: $HEIGHT | Balance: $BALANCE BTC3"
  sleep 10
done
```

### Send with Confirmation

```bash
#!/bin/bash
ADDR="btc31qjnxf60l7rvrs72p45u8gg5e33vxxt6rt6scp27"
AMOUNT=10.0

# Send transaction
TXID=$(btc3-cli sendtoaddress "$ADDR" $AMOUNT)
echo "Transaction sent: $TXID"

# Mine a block to confirm
MINING_ADDR=$(btc3-cli getnewaddress)
btc3-cli generatetoaddress 1 "$MINING_ADDR"

# Verify confirmation
CONFIRMATIONS=$(btc3-cli gettransaction "$TXID" | jq -r '.confirmations')
echo "Confirmations: $CONFIRMATIONS"
```

## Help Commands

### List All Commands

```bash
btc3-cli help
```

### Get Help for Specific Command

```bash
btc3-cli help <command>
```

**Example**:
```bash
btc3-cli help sendtoaddress
```

## Tips

1. **Use jq for JSON parsing**: `btc3-cli getblockchaininfo | jq '.blocks'`
2. **Save common commands as aliases**: `alias btc3='btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin'`
3. **Check command syntax**: Always use `btc3-cli help <command>` if unsure
4. **Batch operations**: Use shell loops for repetitive tasks
5. **Monitor logs**: Check `btc3-data/debug.log` for detailed information

## Next Steps

- [Start mining](MINING.md) to earn BTC3
- [Join the network](JOINING.md) to connect with other nodes
- Explore advanced RPC features in Bitcoin Core documentation

