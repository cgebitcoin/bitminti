// Copyright (c) 2009-2010 Satoshi Nakamoto
// Copyright (c) 2009-present The Bitcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <primitives/block.h>

#include <hash.h>
#include <tinyformat.h>

#include <common/args.h>
#include <node/protocol_version.h>
#include <streams.h>

#include <atomic>
#include <cstdio>
#include <logging.h>
#include <mutex>
#include <randomx.h>
#include <shared_mutex>
#include <vector>

uint256 CBlockHeader::GetHash() const {
  return (HashWriter{} << *this).GetHash();
}

// Global RandomX context management
// This is a naive implementation for demonstration/functionality functionality.
// Production implementations should manage flags and cache properly.
// Global RandomX context management
// Global RandomX cache management
static randomx_cache *rx_cache = nullptr;
static randomx_dataset *rx_dataset = nullptr; // Null for light mode
static std::shared_mutex rx_cache_mutex;
static uint256 rx_current_seed;
static std::atomic<uint64_t> rx_cache_version{0};

// Thread-local VM to avoid contention and race conditions
thread_local randomx_vm *rx_vm = nullptr;
thread_local uint256 rx_vm_seed;
thread_local uint64_t rx_vm_cache_version = 0;

uint256 CBlockHeader::GetPoWHash(const uint256 &seed) const {
  static thread_local std::vector<unsigned char> data(80);
  static thread_local char hash_out[RANDOMX_HASH_SIZE];

  // 1. Fast Path check
  if (rx_vm == nullptr || rx_vm_seed != seed ||
      rx_vm_cache_version != rx_cache_version.load(std::memory_order_relaxed)) {
    // Slow Path (Updating Global Cache if needed)
    {
      std::unique_lock<std::shared_mutex> lock(rx_cache_mutex);
      if (rx_cache == nullptr || seed != rx_current_seed) {
        if (rx_cache != nullptr)
          randomx_release_cache(rx_cache);
        if (rx_dataset != nullptr) {
          randomx_release_dataset(rx_dataset);
          rx_dataset = nullptr;
        }

        randomx_flags flags = randomx_get_flags();
        rx_cache = randomx_alloc_cache(flags);
        randomx_init_cache(rx_cache, seed.begin(), 32);

        if (gArgs.GetBoolArg("-miningfastmode", false)) {
          rx_dataset = randomx_alloc_dataset(flags);
          uint32_t count = randomx_dataset_item_count();
          randomx_init_dataset(rx_dataset, rx_cache, 0, count);
        }

        rx_current_seed = seed;
        rx_cache_version.fetch_add(1, std::memory_order_release);
      }
    }

    // Thread-Local VM Update (Shared Lock)
    randomx_cache *current_cache_ptr = nullptr;
    randomx_dataset *current_dataset_ptr = nullptr;
    uint64_t current_version = 0;
    {
      std::shared_lock<std::shared_mutex> lock(rx_cache_mutex);
      current_cache_ptr = rx_cache;
      current_dataset_ptr = rx_dataset;
      current_version = rx_cache_version.load(std::memory_order_acquire);
    }

    if (rx_vm == nullptr || rx_vm_seed != seed ||
        rx_vm_cache_version != current_version) {
      if (rx_vm != nullptr)
        randomx_destroy_vm(rx_vm);
      if (current_cache_ptr != nullptr) {
        randomx_flags flags = randomx_get_flags();
        if (current_dataset_ptr != nullptr)
          flags |= RANDOMX_FLAG_FULL_MEM;
        fprintf(stderr, "RandomX: creating VM with flags 0x%x\n",
                (unsigned int)flags);
        rx_vm =
            randomx_create_vm(flags, current_cache_ptr, current_dataset_ptr);
        rx_vm_seed = seed;
        rx_vm_cache_version = current_version;
      }
    }
  }

  // 2. HASH Path (Optimal, no locks, if VM is ready)
  if (rx_vm != nullptr) {
    VectorWriter(data, 0) << *this;
    randomx_calculate_hash(rx_vm, data.data(), 80, hash_out);
    return uint256(std::span<const unsigned char>(
        reinterpret_cast<const unsigned char *>(hash_out), 32));
  }

  return uint256{};
}

std::string CBlock::ToString() const {
  std::stringstream s;
  s << strprintf(
      "CBlock(hash=%s, ver=0x%08x, hashPrevBlock=%s, hashMerkleRoot=%s, "
      "nTime=%u, nBits=%08x, nNonce=%u, vtx=%u)\n",
      GetHash().ToString(), nVersion, hashPrevBlock.ToString(),
      hashMerkleRoot.ToString(), nTime, nBits, nNonce, vtx.size());
  for (const auto &tx : vtx) {
    s << "  " << tx->ToString() << "\n";
  }
  return s.str();
}
