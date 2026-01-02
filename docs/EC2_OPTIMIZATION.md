# Optimization Guide for AWS c5.4xlarge

The `c5.4xlarge` is a powerful instance with **16 vCPUs** (8 Physical Cores) and **32GB RAM**.
To get maximum performance for BitMinti (RandomX), you must tune the Linux kernel and configuration.

## 1. Enable Huge Pages (Critical for RandomX)
RandomX performs 2-3x faster if it can lock 2.5GB of RAM into "Huge Pages".
By default, Linux does not allocate enough.

**Run this command (requires sudo):**
```bash
# Allocate 3000 huge pages (approx 6GB, plenty for RandomX)
sudo sysctl -w vm.nr_hugepages=3000
```
To make it permanent, add `vm.nr_hugepages=3000` to `/etc/sysctl.conf`.

## 2. Calculate Optimal Threads (L3 Cache Rule)
RandomX needs **2MB of L3 Cache** per mining thread.
*   **c5.4xlarge L3 Cache:** ~25 MB (Intel Xeon Platinum)
*   **Max Threads:** 25MB / 2MB = **12 Threads**

**Do NOT use 16 threads.**
If you use 16 threads, the CPU cache will thrash, and hashrate will **drop**.
Stick to **12 or 13 threads**.

## 3. High-Performance Start Command
Since you have 32GB RAM, use a massive database cache to speed up block verifying.

```bash
./build/bin/bitmintid \
  -datadir=$HOME/.bitminti \
  -daemon \
  -miningfastmode=1 \
  -dbcache=16384 \
  -par=16
```
*   `-dbcache=16384`: Uses 16GB RAM for the UTXO set (super fast syncing).
*   `-par=16`: Uses all cores for verifying signatures (ECDSA/Schnorr), not mining.

## 4. Mining Command
When you start mining, specify the threads explicitly:

```bash
# Mine using 12 threads (optimal for L3 cache)
./build/bin/bitminti-cli generatetoaddress 1000 <address> 1000000 12
```

## Summary Checklist
1. [ ] `sudo sysctl -w vm.nr_hugepages=3000`
2. [ ] Start daemon with `-dbcache=16384`
3. [ ] Mine with `12` threads (not 16).
