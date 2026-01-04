# BitMinti Pool Integration Guide

Welcome Pool Operators! 🤝

This guide provides everything you need to list **BitMinti ($BM)** on your mining pool.

## ⚡ Network Quick Specs
*   **Coin:** BitMinti
*   **Ticker:** BM
*   **Algorithm:** RandomX (rx/0)
*   **Block Time:** 60 seconds
*   **RPC Port:** 18332 (Default)
*   **P2P Port:** 13337
*   **Difficulty Adjustment:** LWMA (Linear Weighted Moving Average)
*   **Base Code:** Bitcoin Core v28.0 (RPC is 100% Bitcoin compatible)

---

## 🏗️ 1. Daemon Setup

BitMinti uses a standard Bitcoin-style RPC.

**Build:**
```bash
git clone https://github.com/cgebitcoin/bitminti.git
cd bitminti
cmake -B build
cmake --build build -j$(nproc)
```

**Recommended `bitminti.conf`:**
```ini
server=1
daemon=1
listen=1
txindex=1

# RPC Settings
rpcuser=pooluser
rpcpassword=poolpass
rpcport=18332
rpcthreads=16
rpcworkqueue=1000

# Optimization
dbcache=4096
maxconnections=125
```

### 1.1 System Optimization (Huge Pages)
For optimal verification speed (RandomX Fast Mode), enable Huge Pages on your server:

```bash
sudo sysctl -w vm.nr_hugepages=1250
```

Add `-miningfastmode=1` to your daemon startup arguments.

---

## 🛠️ 2. Stratum/Pool Configuration

Since BitMinti uses **RandomX** for PoW but **Bitcoin** for the blockchain structure, standard Bitcoin mining modules work for block templating (`getblocktemplate`), but the **hashing verification** must be RandomX.

### Option A: Miningcore (Recommended)
Add this coin definition to your Miningcore configuration:

```json
{
  "id": "bitminti",
  "name": "BitMinti",
  "canonicalName": "BitMinti",
  "family": "bitcoin",
  "algorithm": "randomx",
  "coinbaseTx": {
      "txVersion": 2,
      "txInputScript": "",
      "txOutputScript": ""
  },
  "daemons": [
    {
      "host": "127.0.0.1",
      "port": 18332,
      "user": "pooluser",
      "password": "poolpass"
    }
  ],
  "ports": {
    "3333": {
      "listenAddress": "0.0.0.0",
      "difficulty": 0.1,
      "varDiff": {
        "minDiff": 0.01,
        "maxDiff": 100,
        "targetTime": 15,
        "retargetTime": 90,
        "variancePercent": 30
      }
    }
  }
}
```

### Option B: Yiimp / Stratum-Mining
Treat it as a Bitcoin-family coin with **RandomX** algo.

*   **Algo:** `randomx`
*   **Symbol:** `BM`
*   **Conf Folder:** `.bitminti`

---

## 🔍 3. Validating Work

The block header structure is standard Bitcoin (80 bytes).
However, the PoW hash is calculated using **RandomX** on the full block header.

If you are writing a custom stratum:
1.  Construct the 80-byte header (standard Bitcoin).
2.  Pass the header to `randomx_calculate_hash(vm, header, 80, output)`.
3.  Compare `output` (reversed) against `target`.

---

## 🎨 4. Branding Assets

*   **Logo:** `bitminti-logo.png` (Included in this folder)
*   **Website:** https://bitminti.com (or your hosting URL)
*   **Explorer:** [Link to your explorer]

---

## 📞 Support

If you have any integration issues, please reach out directly:
*   GitHub Issues: https://github.com/cgebitcoin/bitminti/issues
*   Discord/Telegram: [Link]
*   Email: [Developer Email]

We are happy to assist with custom patches if your pool software requires specific formatting!
