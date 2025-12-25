# Joining the BTC3 Network

This guide explains how to connect to the BTC3 network and participate as a full node or miner.

## Network Overview

BTC3 operates as a peer-to-peer network where nodes:
- Share blocks and transactions
- Validate the blockchain
- Mine new blocks
- Relay information to other peers

## Prerequisites

- BTC3 binaries installed (see [BUILDING.md](BUILDING.md))
- Internet connection
- Port 13337 accessible (for incoming connections)

## Connecting to the Network

### Method 1: Using addnode Command

```bash
# Start your daemon
./bin/btc3d -datadir=./btc3-data -server -rpcuser=admin -rpcpassword=admin -daemon

# Add a seed node (replace with actual IP)
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin addnode "<SEED_NODE_IP>:13337" "add"

# Verify connection
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getpeerinfo
```

### Method 2: Using Configuration File

Create or edit `btc3-data/bitcoin.conf`:

```ini
# RPC settings
rpcuser=admin
rpcpassword=admin
server=1

# Network settings
port=13337
listen=1

# Add seed nodes (replace with actual IPs)
addnode=<SEED_NODE_IP_1>:13337
addnode=<SEED_NODE_IP_2>:13337

# Optional: allow external RPC (be careful!)
# rpcallowip=0.0.0.0/0
# rpcbind=0.0.0.0
```

Then start the daemon:

```bash
./bin/btc3d -datadir=./btc3-data -daemon
```

## Firewall Configuration

### Linux (ufw)

```bash
# Allow incoming connections on port 13337
sudo ufw allow 13337/tcp
sudo ufw reload
```

### macOS

```bash
# Add firewall rule (requires admin)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add ./bin/btc3d
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp ./bin/btc3d
```

### Router Port Forwarding

If behind a router, forward port 13337 to your machine's local IP:
1. Access router admin panel (usually 192.168.1.1)
2. Find "Port Forwarding" or "NAT" settings
3. Forward external port 13337 → internal IP:13337

## Verifying Network Connection

### Check Peer Count

```bash
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getconnectioncount
```

Should return > 0 if connected.

### View Peer Information

```bash
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getpeerinfo
```

Shows detailed info about each connected peer.

### Check Sync Status

```bash
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getblockchaininfo
```

Look for:
- `blocks`: Current block height
- `headers`: Known headers (should match `blocks` when synced)
- `verificationprogress`: Should be 1.0 when fully synced

## Blockchain Synchronization

When you first connect, your node will download the entire blockchain:

```bash
# Monitor sync progress
watch -n 5 './bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getblockcount'
```

BTC3's blockchain is small, so sync should complete in seconds to minutes.

## Running a Seed Node

To help others join the network, run a publicly accessible node:

### 1. Get Your Public IP

```bash
curl ifconfig.me
```

### 2. Configure for Public Access

Edit `btc3-data/bitcoin.conf`:

```ini
# Bind to all interfaces
bind=0.0.0.0:13337

# Allow more connections
maxconnections=125

# Enable listening
listen=1
```

### 3. Start the Daemon

```bash
./bin/btc3d -datadir=./btc3-data -daemon
```

### 4. Share Your IP

Share `<YOUR_PUBLIC_IP>:13337` with others so they can connect.

## Systemd Service (Linux)

For automatic startup, create `/etc/systemd/system/btc3d.service`:

```ini
[Unit]
Description=BTC3 Daemon
After=network.target

[Service]
Type=forking
User=btc3
WorkingDirectory=/home/btc3/btc3/build
ExecStart=/home/btc3/btc3/build/bin/btc3d -datadir=/home/btc3/btc3-data -daemon
ExecStop=/home/btc3/btc3/build/bin/btc3-cli -datadir=/home/btc3/btc3-data stop
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable btc3d
sudo systemctl start btc3d
sudo systemctl status btc3d
```

## Docker Deployment

### Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY build/bin/* /usr/local/bin/

EXPOSE 13337 8332

VOLUME ["/btc3-data"]

CMD ["btc3d", "-datadir=/btc3-data", "-server", "-rpcuser=admin", "-rpcpassword=admin", "-rpcbind=0.0.0.0", "-rpcallowip=0.0.0.0/0", "-fallbackfee=0.00001"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  btc3:
    build: .
    ports:
      - "13337:13337"
      - "8332:8332"
    volumes:
      - btc3-data:/btc3-data
    restart: unless-stopped
    environment:
      - RPC_USER=admin
      - RPC_PASSWORD=admin

volumes:
  btc3-data:
```

Run with:

```bash
docker-compose up -d
```

## Cloud Deployment

### DigitalOcean / AWS / Linode

```bash
# 1. Create a small VPS (1GB RAM is enough)
# 2. SSH into the server
ssh root@<SERVER_IP>

# 3. Install dependencies
apt-get update
apt-get install -y wget tar

# 4. Download BTC3 binaries
wget https://github.com/<your-username>/btc3/releases/download/v0.1.0/btc3-linux-x86_64.tar.gz
tar xzf btc3-linux-x86_64.tar.gz

# 5. Start daemon
./btc3/bin/btc3d -datadir=./btc3-data -daemon

# 6. Open firewall
ufw allow 13337/tcp
```

## Network Monitoring

### Check Network Health

```bash
# Number of peers
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getconnectioncount

# Network info
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getnetworkinfo

# Peer details
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getpeerinfo | jq '.[] | {addr, version, subver}'
```

### Monitor Mempool

```bash
# Mempool info
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getmempoolinfo

# View pending transactions
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getrawmempool
```

## Troubleshooting

### No Peers Connecting

**Possible causes**:
- Firewall blocking port 13337
- Incorrect seed node IP
- Network connectivity issues

**Solutions**:
```bash
# Test port is open
nc -zv <YOUR_IP> 13337

# Check firewall
sudo ufw status

# Verify daemon is listening
netstat -an | grep 13337
```

### Sync Stuck

**Solution**: Restart daemon and re-add seed nodes:
```bash
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin stop
./bin/btc3d -datadir=./btc3-data -daemon
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin addnode "<SEED_IP>:13337" "add"
```

### Connection Refused

**Problem**: Daemon not running or wrong port  
**Solution**: Check daemon status and port:
```bash
ps aux | grep btc3d
netstat -an | grep 13337
```

## Best Practices

1. **Keep daemon running** – Helps network health
2. **Open port 13337** – Allows incoming connections
3. **Use systemd/docker** – Ensures automatic restart
4. **Monitor logs** – Check `btc3-data/debug.log` for issues
5. **Backup wallet** – Regularly backup wallet files
6. **Update software** – Keep BTC3 updated to latest version

## Next Steps

- [Start mining](MINING.md) to earn BTC3
- [Use RPC commands](RPC.md) to interact with the network
- Share your node IP to help others connect

