// Copyright (c) 2009-2010 Satoshi Nakamoto
// Copyright (c) 2009-present The Bitcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <pow.h>

#include <arith_uint256.h>
#include <chain.h>
#include <primitives/block.h>
#include <uint256.h>
#include <util/check.h>

unsigned int GetNextWorkRequired(const CBlockIndex *pindexLast,
                                 const CBlockHeader *pblock,
                                 const Consensus::Params &params) {
  assert(pindexLast != nullptr);
  unsigned int nProofOfWorkLimit = UintToArith256(params.powLimit).GetCompact();

  // BTC5: N=90 for RandomX CPU mining stability.
  // Reduced from 500 to better reflect CPU network realities while keeping fair
  // launch logic.
  const int64_t N = 90;

  // Default to powLimit if chain is too short
  if (pindexLast->nHeight < N) {
    return nProofOfWorkLimit;
  }

  // Loop through N blocks to calculate Weighted Solvetimes and Average Target
  arith_uint256 sumTarget = 0;
  int64_t nWeightedSolvetimes = 0;
  int64_t nWeightSum = 0;

  const CBlockIndex *pindex = pindexLast;
  for (int64_t i = N; i > 0; i--) {
    arith_uint256 target;
    target.SetCompact(pindex->nBits);

    // Canonical LWMA: Targets must be weighted too
    arith_uint256 weightedTarget = target * arith_uint256((uint64_t)i);
    sumTarget += weightedTarget;

    // Solve time for this block
    int64_t solvetime = 1;
    if (pindex->pprev) {
      solvetime = pindex->GetBlockTime() - pindex->pprev->GetBlockTime();
    }

    // BTC5 Smooth Takeoff & Solvetime Floor:
    // 1. If in grace period (< N), fake perfect timing to prevent history
    // poisoning.
    // 2. Otherwise, enforce a minimum solvetime of TargetSpacing/4 (150s) to
    // prevent oscillations.
    if (pindex->nHeight < N) {
      solvetime = params.nPowTargetSpacing;
    } else {
      int64_t minSolve = params.nPowTargetSpacing / 4;
      if (solvetime < minSolve)
        solvetime = minSolve;
    }

    // Max clamp 6x
    if (solvetime > 6 * params.nPowTargetSpacing)
      solvetime = 6 * params.nPowTargetSpacing;

    // Linearly weighted sum
    nWeightedSolvetimes += solvetime * i;
    nWeightSum += i;

    pindex = pindex->pprev;
  }

  // Average Target = WeightedTargetSum / WeightSum
  arith_uint256 avgTarget = sumTarget / arith_uint256((uint64_t)nWeightSum);

  // Adjusted Target = AvgTarget * ( (WeightedSolvetimes / WeightSum) /
  // TargetSpacing ) Rewritten for precision: AvgTarget * WeightedSolvetimes /
  // (WeightSum * TargetSpacing)

  arith_uint256 bnNew = avgTarget;
  bnNew *= arith_uint256((uint64_t)nWeightedSolvetimes);
  // Cast the denominator product to arith_uint256
  bnNew /= arith_uint256((uint64_t)(nWeightSum * params.nPowTargetSpacing));

  // Per-block difficulty clamp (Tightened for CPU Stability)
  arith_uint256 prev;
  prev.SetCompact(pindexLast->nBits);

  // Harder (Target smaller): Max +11% difficulty change
  arith_uint256 maxUp = prev * arith_uint256(90) / arith_uint256(100);

  // Easier (Target larger): Max -10% difficulty change
  arith_uint256 maxDown = prev * arith_uint256(110) / arith_uint256(100);

  if (bnNew < maxUp)
    bnNew = maxUp;
  if (bnNew > maxDown)
    bnNew = maxDown;

  if (bnNew > UintToArith256(params.powLimit))
    bnNew = UintToArith256(params.powLimit);

  return bnNew.GetCompact();
}

unsigned int CalculateNextWorkRequired(const CBlockIndex *pindexLast,
                                       int64_t nFirstBlockTime,
                                       const Consensus::Params &params) {
  // unused in LWMA, but kept for compilation compatibility if needed
  return GetNextWorkRequired(pindexLast, nullptr, params);
}

// Check that on difficulty adjustments, the new difficulty does not increase
// or decrease beyond the permitted limits.
bool PermittedDifficultyTransition(const Consensus::Params &params,
                                   int64_t height, uint32_t old_nbits,
                                   uint32_t new_nbits) {
  // BTC3: LWMA changes difficulty every block.
  // We must disable the restrictive Bitcoin legacy checks.
  return true;
}

// Bypasses the actual proof of work check during fuzz testing with a simplified
// validation checking whether the most significant bit of the last byte of the
// hash is set.
bool CheckProofOfWork(uint256 hash, unsigned int nBits,
                      const Consensus::Params &params) {
  if (EnableFuzzDeterminism())
    return (hash.data()[31] & 0x80) == 0;
  return CheckProofOfWorkImpl(hash, nBits, params);
}

std::optional<arith_uint256> DeriveTarget(unsigned int nBits,
                                          const uint256 pow_limit) {
  bool fNegative;
  bool fOverflow;
  arith_uint256 bnTarget;

  bnTarget.SetCompact(nBits, &fNegative, &fOverflow);

  // Check range
  if (fNegative || bnTarget == 0 || fOverflow ||
      bnTarget > UintToArith256(pow_limit))
    return {};

  return bnTarget;
}

bool CheckProofOfWorkImpl(uint256 hash, unsigned int nBits,
                          const Consensus::Params &params) {
  auto bnTarget{DeriveTarget(nBits, params.powLimit)};
  if (!bnTarget)
    return false;

  // Check proof of work matches claimed amount
  if (UintToArith256(hash) > bnTarget)
    return false;

  return true;
}
