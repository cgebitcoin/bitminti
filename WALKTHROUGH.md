# BTC3 Launch & Verification Walkthrough

## 1. The "Instamine" Fix
This release fixes the critical difficulty adjustment bug where miners could mine blocks instantly.
- **Algorithm**: Replaced standard Bitcoin retargeting with **LWMA (Linearly Weighted Moving Average)**.
- **Behavior**: Difficulty adjusts *every block* based on the last 45 blocks.
- **Params**: Standard Bitcoin Proof-of-Work limit (Difficulty 1.0).

### Next Steps
- Verify mining of new blocks using `bitcoin-cli generateblock`.
- Adjust `powLimit` and difficulty parameters for production readiness if needed (currently relaxed for development).

## Troubleshooting

### CMake Error: "imported target references file that does not exist"
If you see errors complaining that libraries in `depends` (like `libevent`) reference paths that do not exist (e.g. referencing `btc3/depends` when the folder is actually outside), it means the hardcoded paths in the `depends` configuration are stale.

**Fix:**
Regenerate the depends configuration by running `make` in the depends directory:
```bash
cd /path/to/depends
make HOST=x86_64-pc-linux-gnu
```
Then re-run `cmake` in your build directory.

## 2. Official Genesis Block
You must use this specific Genesis Block to be on the valid chain:
- **Nonce**: `1897862476`
- **Time**: `1766971600`
- **Hash**: `00000000f83ead17d3e775fb2cd5558a2108401e0c0a026c616d0b01dfa40ddf`
- **Merkle Root**: `d086f74285d50bb21873d47b675d88a5886c1535f7650b1803bb5ad3b0abbe67`

## 3. How to Verify (Run Your Own Node)
Since the Genesis Block has changed, you must start fresh.

### Step 1: Clean Data
```bash
rm -rf ~/.btc3
# OR if on Mac/Default:
rm -rf "$HOME/Library/Application Support/Bitcoin"
```

### Step 2: Start Node
```bash
./build/bin/btc3d -daemon
```

### Verification Step: Mining Mainnet
We confirmed that mining is functional.
- **Fast Mode (EC2)**: Achieved ~5000+ H/s using `t3.medium` (4GB RAM) or larger.
- **Light Mode (Mac)**: Verified functionality (~60 H/s) due to OS limitations.
- **Legacy Builds**: Created `setup_and_build_legacy.sh` to produce binaries for older Linux kernels (Ubuntu 14.04+).

To mine on EC2 (Best Performance):
1. Start Node: `sudo ./start-node.sh`
2. Start Miner: `sudo ./mine-ec2.sh` (Uses all cores + Fast Mode)


## 4. Verification Step: Mining Mainnet
**Success!** The network is live and mining.
- **Current Height:** Block 60+ (Confirmed by user on EC2)
- **Algorithm:** RandomX (CPU) + LWMA Difficulty Adjustment.
- **Peer Connection:** EC2 <-> MacOS verified.

#### How to Check Status
```bash
# On EC2 or Mac:
./build/bin/btc3-cli -rpcuser=test -rpcpassword=test getblockchaininfo
```

## 5. Mining (Fast Mode & Multi-Threaded)
To achieve maximum CPU mining performance (~100x faster than default), follow these steps:

### Step 1: Start Daemon in Fast Mode
Enable the RandomX "Full Memory" dataset (requires ~2.5GB RAM) at startup.
```bash
./build/bin/btc3d -daemon -miningfastmode=1
```

### Step 2: Start Multi-Threaded Mining
Use the CLI to mine blocks using all available CPU cores.
```bash
# Calculate number of cores
THREADS=$(nproc)

# Mine 1000 blocks to your address with all cores
./build/bin/btc3-cli generatetoaddress 1000 "$(./build/bin/btc3-cli getnewaddress)" 10000000 $THREADS
```

## 6. Deployment / Release Instructions

### ⚠️ IMPORTANT: Legacy Linux Support (Ubuntu 14.04/16.04/18.04)
If you are deploying to an older Linux server, you **MUST** use the `legacy` binary release (`btc3-linux-legacy.tar.gz`).

**Why?**
The standard binaries are compiled with a modern GLIBC (2.35+). Older systems use older GLIBC versions (e.g., Ubuntu 18.04 uses 2.27). Running the standard binary on them will cause this error:
```
./btc3d: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.34' not found
```

**Files:**
- `btc3-linux-x86_64.tar.gz` → For Ubuntu 22.04 / 24.04 (Modern)
- `btc3-linux-legacy.tar.gz` → For Ubuntu 14.04 - 20.04 (Legacy / Universal)
