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

### Step 3: Check Difficulty
```bash
./build/bin/btc3-cli getmininginfo
```
Output should show:
- `"difficulty": 1`
- `"blocks": 0`

### Step 4: Mine (Proof of Fix)
To prove the chain is not broken/instant:
```bash
./build/bin/btc3-cli geeneratetoaddress 1 <your_wallet_address>
```
- **Observation**: It will take minutes/hours on a CPU. This confirms the difficulty is working.

## 4. Connectivity
- **P2P Port**: 13337
- **RPC Port**: 8332
