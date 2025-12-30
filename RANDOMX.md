# RandomX Migration Documentation

This document outlines the changes made to migrate the BTC3 Proof-of-Work algorithm from SHA256 to RandomX.

## 1. Overview

The primary goal was to replace the standard Bitcoin SHA256 Proof-of-Work with RandomX to increase ASIC resistance and enable CPU mining. This involved:
- Integrating the `librandomx` library.
- Implementing a new PoW hashing method (`GetPoWHash`).
- Updating block validation logic (`CheckProofOfWork`).
- Re-mining the genesis block with valid RandomX parameters.

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

### Validation (`src/validation.cpp` & `src/rpc/mining.cpp`)
- **`CheckBlockHeader`**: Modified to call `CheckProofOfWork` using `block.GetPoWHash()` instead of `block.GetHash()`.
- **`GenerateBlock`**: Updated the mining loop to check difficulty against `block.GetPoWHash()`.

## 4. Genesis Block

A new genesis block was mined to satisfy the RandomX difficulty requirements.

**Parameters:**
- **Time**: `1766971600`
- **Nonce**: `0` (Mined with relaxed difficulty for development)
- **nBits**: `0x207fffff` (Relaxed target)
- **Hash (SHA256)**: `d087346dab70b4a35852253310842a4d741b2d3c8afb140118b3430f18843ef7`
- **Merkle Root**: `d086f74285d50bb21873d47b675d88a5886c1535f7650b1803bb5ad3b0abbe67`

## 5. Building and Running

### Build
```bash
mkdir build && cd build
cmake ..
make -j$(nproc)
```

### Run
```bash
./src/btc3d -printtoconsole
```
The node should start and accept the new genesis block.
