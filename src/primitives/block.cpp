// Copyright (c) 2009-2010 Satoshi Nakamoto
// Copyright (c) 2009-present The Bitcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <primitives/block.h>

#include <hash.h>
#include <tinyformat.h>

#include <node/protocol_version.h>
#include <streams.h>

#include <mutex>
#include <randomx.h>
#include <vector>

uint256 CBlockHeader::GetHash() const {
  return (HashWriter{} << *this).GetHash();
}

// Global RandomX context management
// This is a naive implementation for demonstration/functionality functionality.
// Production implementations should manage flags and cache properly.
static randomx_dataset *rx_dataset = nullptr;
static randomx_cache *rx_cache = nullptr;
static randomx_vm *rx_vm = nullptr;
static std::once_flag rx_init_flag;
static std::mutex rx_mutex;

void InitRandomX() {
  std::call_once(rx_init_flag, []() {
    randomx_flags flags = randomx_get_flags();
    rx_cache = randomx_alloc_cache(flags);
    randomx_init_cache(rx_cache, "btc3_seed_key", 13); // Fixed key for now
    rx_vm = randomx_create_vm(flags, rx_cache, nullptr);
  });
}

uint256 CBlockHeader::GetPoWHash() const {
  InitRandomX();

  // Serialize header to a buffer
  std::vector<unsigned char> data;
  VectorWriter(data, 0) << *this;

  char hash[RANDOMX_HASH_SIZE];
  {
    std::lock_guard<std::mutex> lock(rx_mutex);
    randomx_calculate_hash(rx_vm, data.data(), data.size(), hash);
  }

  return uint256(std::vector<unsigned char>(hash, hash + 32));
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
