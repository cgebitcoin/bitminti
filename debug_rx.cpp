#include "src/randomx/src/randomx.h"
#include <cstring>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

std::vector<uint8_t> parse_hex(const std::string &hex) {
  std::vector<uint8_t> bytes;
  for (size_t i = 0; i < hex.length(); i += 2) {
    std::string byteString = hex.substr(i, 2);
    uint8_t byte = (uint8_t)strtol(byteString.c_str(), nullptr, 16);
    bytes.push_back(byte);
  }
  return bytes;
}

int main(int argc, char *argv[]) {
  if (argc < 3) {
    std::cerr << "Usage: debug_rx <seed_hex> <blob_hex>" << std::endl;
    return 1;
  }

  std::string seed_hex = argv[1];
  std::string blob_hex = argv[2];

  std::vector<uint8_t> seed = parse_hex(seed_hex);
  std::vector<uint8_t> blob = parse_hex(blob_hex);

  randomx_flags flags = randomx_get_flags();
  randomx_cache *myCache = randomx_alloc_cache(flags);
  randomx_init_cache(myCache, seed.data(), seed.size());

  randomx_vm *myMachine = randomx_create_vm(flags, myCache, nullptr);
  if (!myMachine) {
    std::cerr << "Failed to create VM" << std::endl;
    return 1;
  }

  uint8_t hash[RANDOMX_HASH_SIZE];
  randomx_calculate_hash(myMachine, blob.data(), blob.size(), hash);

  for (int i = 0; i < RANDOMX_HASH_SIZE; ++i) {
    std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)hash[i];
  }
  std::cout << std::endl;

  randomx_destroy_vm(myMachine);
  randomx_release_cache(myCache);

  return 0;
}
