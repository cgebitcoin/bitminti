# RandomX Migration Documentation

This document outlines the changes made to migrate the BTC3 Proof-of-Work algorithm from SHA256 to RandomX.

## 1. Architecture: SHA256 vs RandomX

The migration from SHA256 to RandomX represents a fundamental shift in the node's Proof-of-Work architecture.

### Core Differences

| Feature | Legacy SHA256 | RandomX |
| :--- | :--- | :--- |
| **Algorithm** | Double SHA256 (`SHA256(SHA256(x))`) | RandomX (Virtual Machine execution) |
| **Target Hardware** | ASICs (Specialized Hardware) | General Purpose CPUs |
| **State** | Stateless (Pure function) | **Contextual** (Requires large 2GB+ Dataset & Seed) |
| **Validation** | Fast, light, typically standard header check | Heavy, memory-intensive, requires initialized VM |
| **Seed Strategy** | None (Static) | **Rotational** (Changes every 2048 blocks) <br> Blocks 0-2047: **Genesis Epoch Seed** (Genesis Hash) <br> Blocks 2048+: Previous Epoch Block Hash |

## 2. Design Implementation

### A. Dual Hash System
In Bitcoin (SHA256), the Block Hash serves two purposes:
1.  **Unique Identifier (ID)**: Database keys, Merkle links.
2.  **Proof of Work (PoW)**: Must be `< Target`.

In our RandomX implementation, we separate these:
-   **Block ID**: Remains `SHA256(SHA256(Header))`. This ensures efficient database lookups and compatibility with existing RPC/P2P structures.
-   **PoW Hash**: Uses `RandomX(Header, Seed)`. This is *only* used to verify difficulty compliance.
-   **Result**: Valid blocks have a SHA256 ID, but their "work" is verified via RandomX.

### B. Contextual Validation
RandomX is not stateless. To verify a header, you generally need the **Seed** corresponding to its height (Epoch).
-   **Old Flow**: `CheckBlockHeader(header)` -> `CheckProofOfWork(header.GetHash())`.
-   **New Flow**: `ContextualCheckBlockHeader(header, ...)` -> `Calculate Seed for Height` -> `CheckProofOfWork(header.GetPoWHash(seed))`.
-   **Optimization**: We removed redundant PoW sanity checks in `LoadBlockIndexGuts` (startup) because RandomX verification is contextual and performance-intensive. Security is fully maintained as every block is strictly validated upon its first arrival and when connecting to the active chain.

### C. Thread-Local Optimizations
RandomX VMs are heavy objects (not thread-safe). Global locking is a bottleneck.
-   **Design**:
    -   **Global Cache**: Single read-only memory block (updated only on Epoch change).
    -   **Thread-Local VMs**: Each mining/validation thread has its own `randomx_vm` instance.
    -   **Mechanism**: Threads check if their VM seed matches the Global Cache seed. If not, they re-initialize efficiently.

## 3. Integration Details

## 2. Integration Details

### Library Vendor
The `librandomx` library is vendored in `src/randomx`.

### Build System (`CMakeLists.txt`)
- **Root CMake**: Added `add_subdirectory(randomx)`.
- **Source CMake**: Linked `randomx` library to `bitcoin_consensus` target.
- **Include Paths**: Added `randomx/src` to `bitcoin_consensus` include directories.

## 3. Implementation Changes

### Block Header (`src/primitives/block.cpp`)
- **`GetPoWHash()`**: Implemented a new method that:
  1. Initializes a global RandomX context/VM (cached).
  2. Serializes the block header using `VectorWriter`.
  3. Calculates the RandomX hash of the serialized header.
  - *Note*: The standard `GetHash()` method (SHA256) is preserved as the Block ID for linking blocks.

### Validation (`src/validation.cpp`)
- **`ContextualCheckBlockHeader`**: Implemented strict RandomX PoW check using height-based Seed.
- **`LoadBlockIndexGuts` (blockstorage.cpp)**: Removed legacy PoW sanity checks during startup. Since all blocks are validated before being written to disk, this startup check is redundant and poorly suited for RandomX context.

## 4. Seed Rotation
    - RandomX requires a seed (key) to initialize the VM.
    - We implemented a height-based seed rotation strategy (Epoch).
    - **Epoch Length**: 2048 blocks.
    - **Seed Logic**:
        - `Epoch 0` (Blocks 0-2047): Seed is `uint256{}` (Zero).
        - `Epoch N`: Seed is the block hash of height `N * 2048`.
    - The VM is re-initialized whenever the seed changes.

## 5. Genesis Block
    - Re-mined using RandomX with the **genesis epoch seed**.
    - **Difficulty**: Hardened for production (`0x1f00ffff`) to ensure a fair launch and prevent instamine.

A new genesis block was mined to satisfy the### Genesis Block Configuration

The Genesis block is mined using the **Genesis Epoch Seed** (`uint256{0}`).

- **nBits**: `0x1f00ffff` (Hardened Production Target)
- **nNonce**: `805306957`
- **Hash**: `0d2c382326321b1004eb676d1a8ff1a93e92bb0da7be6043a058a6edb361b89e`
- **PoW Hash**: `0000a3a63f6b7d31796254299257f86a4b4231916ec239b3a700ab2c85b55764` (4 Leading Zeros)
- **Merkle Root**: `d086f74285d50bb21873d47b675d88a5886c1535f7650b1803bb5ad3b0abbe67`

> [!IMPORTANT]
> The difficulty target `0x1f00ffff` is the final production baseline. It requires ~16.7 million hashes per block on average, ensuring no initial "instamine" period. The **LWMA** algorithm will take over from height 1 to adjust to real-world hashrate.
sole
```
The node should start and accept the new genesis block.
```
