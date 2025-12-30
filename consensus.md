# BTC3 Consensus Specification

**Network:** BTC3 Mainnet  
**Consensus Version:** v1.0.0-randomx-hardened  
**Status:** 🔒 Consensus Frozen

---

## 1. Scope and Authority

This document is the **authoritative specification** of the BTC3 mainnet consensus rules. Any change to the rules described here **requires a hard fork**.

BTC3 is a Bitcoin-Core–derived blockchain designed for:
- Long-term **CPU mining viability** via RandomX.
- Strong **ASIC resistance**.
- Resistance to **instamine**, **difficulty collapse**, and **hashrate shock**.
- Deterministic, auditable, Bitcoin-style validation semantics.

---

## 2. Block Structure

BTC3 uses the standard Bitcoin block and transaction structure with a **Dual-Hash Model**.

### 2.1 Block Header Fields

| Field | Description |
|------|-------------|
| `nVersion` | Block version |
| `hashPrevBlock` | SHA256 block ID of the previous block |
| `hashMerkleRoot` | Merkle root of all transactions |
| `nTime` | Block timestamp (Unix epoch seconds) |
| `nBits` | Compact difficulty target |
| `nNonce` | Nonce value |

### 2.2 Dual-Hash Model
- **Block ID**: Double-SHA256 of the block header. Used for chain linking, indexing, and seed derivation.
- **PoW Hash**: RandomX hash used exclusively for Proof-of-Work weight validation.

---

## 3. Proof-of-Work Algorithm

- **Algorithm:** RandomX (CPU-optimized, memory-hard).
- **PoW Validity Rule:** `RandomX_PoW_Hash(block_header, seed) ≤ Target(nBits)`
- **Target Invariant:** `Target(nBits)` must be **≤ powLimit**.

---

## 4. RandomX Seed Derivation

RandomX requires a deterministic seed derived from block height `H`.

### 4.1 Epoch Rules
- **Epoch Length:** 2048 blocks.
- **Seed Height Calculation:** `seed_height = floor(H / 2048) × 2048`

### 4.2 Seed Value
- **Height 0 (Genesis Epoch):** A zero-initialized `uint256`.
- **H > 0:** The **Block ID (SHA256)** of the block at `seed_height`.

---

## 5. Difficulty Adjustment (LWMA)

BTC3 uses **LWMA (Linearly Weighted Moving Average)** for per-block difficulty adjustment.

| Parameter | Value |
|----------|-------|
| Target block time | 600 seconds (10 minutes) |
| LWMA window (N) | 45 blocks |
| Adjustment frequency | Every block |
| Maximum change per block | ±2× |

LWMA ensures the network reacts quickly to hashrate changes while maintaining a stable average 10-minute block time.

---

## 6. Difficulty Limits

### 6.1 powLimit (Minimum Difficulty Floor)
The absolute maximum target (minimum difficulty) allowed on Mainnet:
```
000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
```
The network will never allow difficulty easier than this floor, preventing "zero-cost" instamine attacks.

---

## 7. Genesis Block

The BTC3 genesis block is the immutable foundation of the chain.

| Parameter | Value |
| :--- | :--- |
| **nBits** | `0x1f00ffff` (Hardened Production Target) |
| **nNonce** | `805306957` |
| **Block ID (SHA256)** | `0d2c382326321b1004eb676d1a8ff1a93e92bb0da7be6043a058a6edb361b89e` |
| **PoW Hash** | `0000a3a63f6b7d31796254299257f86a4b4231916ec239b3a700ab2c85b55764` |

---

## 8. Timestamp and Header Validation
- **Median Time Past (MTP):** nTime must be > MTP of previous 11 blocks.
- **Contextual PoW:** PoW is validated against the correct RandomX seed for the specific height.
- **Mining Templates:** PoW checks are skipped for incomplete templates in `TestBlockValidity` but fully enforced upon block submission.

---
**End of BTC3 Consensus Specification**
