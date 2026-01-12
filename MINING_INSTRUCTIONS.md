# BitMinti RandomX Mining Instructions

This guide explains how to mine BitMinti (RandomX Algorithm) using XMRig and the custom Stratum Proxy.

## Status: Integration Verified
*   **Stratum Protocol:** Working (XMRig connects, authenticates, receives jobs).
*   **Job Generation:** Working (Proxy creates valid Stratum jobs from BitMinti templates).
*   **Submission:** Working (Proxy accepts shares, reconstructs blocks, submits to Daemon).
*   **PoW Validation:** **Partial**. Daemon receives blocks but rejects them with `high-hash` (PoW Failed), indicating a hash mismatch likely due to RandomX Seed/Key differences between XMRig defaults and BitMinti daemon. **This requires C++ debugging of the Daemon's RandomX initialization.**

## Components
1.  **BitMinti Node**: The Bitcoin fork running RandomX.
2.  **monminti.py**: The Stratum Bridge (Proxy).
3.  **XMRig**: The external miner software.

## 1. Start BitMinti Node
Ensure your node is running and has RPC enabled.
```bash
# Mainnet
./bitmintid -datadir=/home/ubuntu/btc3
```

## 2. Start Stratum Proxy
The proxy listens on port `3333` and bridges XMRig to BitMinti RPC.

**Configuration:**
Edit `monminti.py`:
*   `BITCOIN_RPC_URL`: `http://127.0.0.1:13336` (Port used by Node)
*   `BITCOIN_USER` / `PASS`: `admin` / `admin`
*   `DEFAULT_PAYOUT`: Your Legacy Address (`1...`).
*   **Target:** Set `target = "ff000000"` for Mainnet to avoid log flooding.

**Run the Proxy:**
```bash
python3 monminti.py
```

## 3. Run XMRig
Run XMRig in **Stratum Mode**.

```bash
./xmrig -o 127.0.0.1:3333 \
  -u YOUR_BITMINTI_LEGACY_ADDRESS \
  --algo=rx/0 \
  --randomx-mode=light
```

## Troubleshooting
*   **"RPC Error 500"**: Means Daemon rejected the block submission. Check Daemon logs (`debug.log`).
*   **"high-hash"**: The block was constructed correctly, but the calculated hash did not meet the target. This currently happens even on Regtest, pointing to the Seed Mismatch issue.

## Future Work (C++)
To fix the `high-hash` validation failure:
1.  Inspect BitMinti `src/pow.cpp` and `src/primitives/block.cpp`.
2.  Determine exactly what 32-byte `seed` is passed to `randomx_create_vm`.
3.  Compare this `seed` with what XMRig logs as `seed_hash`.
4.  Ensure Endianness matches (RPC `getblockhash` returns Big Endian Hex; RandomX might need Little Endian Bytes).
