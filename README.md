# BTC3 – The Next Generation Cryptocurrency

FIRST READ OUR MANIFESTO [MANIFESTO.md](MANIFESTO.md)

SECOND READ OUR CONSENSUS [consensus.md](consensus.md)

**BTC3** is an independent cryptocurrency built on Bitcoin Core technology, designed for accessibility and modern blockchain features. It utilizes the **RandomX** Proof-of-Work algorithm to ensure long-term CPU mining viability and strong ASIC resistance.

## 💡 Why BTC3 Exists

**Cryptocurrency was meant to empower ordinary people, not enrich the wealthy.**

When Bitcoin launched in 2009, anyone could mine it on a laptop. It was truly decentralized and accessible. But over the years, Bitcoin and other cryptocurrencies have become dominated by:

- 🏦 **Wealthy investors** who bought early and hold massive positions
- 🏭 **Mining corporations** with industrial-scale operations
- 🐋 **Whales** who manipulate markets for profit
- 💰 **Venture capitalists** who control ICOs and premines
- 🎰 **Speculators** who treat crypto as a casino

**The original vision has been lost.** Ordinary people are priced out, squeezed by whales, and left watching from the sidelines while the rich get richer.

### BTC3 Changes This

BTC3 returns to cryptocurrency's roots with a simple principle: **Everyone should have an equal opportunity to participate.**

**How we're different:**

✊ **No Premine** – Not a single coin was created before public launch  
✊ **No ICO** – No wealthy investors got early access  
✊ **No Whales** – Everyone starts from zero  
✊ **CPU Mining** – Anyone with a computer can mine  
✊ **Fair Launch** – No insider advantages  
✊ **For the People** – Built to benefit ordinary users, not elites  

### The Problem We're Solving

**Bitcoin today:**
- Requires $10,000+ ASIC miners to participate
- Dominated by mining pools controlled by corporations
- Early adopters hold massive positions
- Ordinary people can only buy at inflated prices

**BTC3 today:**
- Mine on any laptop or desktop
- No specialized hardware needed
- Everyone starts equal
- Earn by participating, not by being wealthy

### Our Mission

**BTC3 exists to give power back to the people.**

We believe:
- 🌍 Cryptocurrency should be accessible to everyone, everywhere
- ⚖️ Fair distribution is more important than enriching early investors
- 💪 Ordinary people deserve the same opportunities as the wealthy
- 🔓 Financial freedom shouldn't require massive capital
- 🤝 Community matters more than profit

**This is cryptocurrency for the 99%, not the 1%.**

## 🚀 Key Features

- **ASIC Resistance** – Utilizes the RandomX PoW algorithm, designed specifically for commodity CPUs and memory-hard validation.
- **Fair Distribution** – No premine, no ICO, pure proof-of-work from a hardened production genesis.
- **Modern from Day 1** – SegWit, CSV, and all major soft forks active from block 1.
- **Independent Network** – Runs on port 13337 with unique magic bytes (`0xfc,0xc1,0xb7,0xdc`).
- **Full Bitcoin Compatibility** – All RPC commands work exactly as in Bitcoin Core.
- **Recognizable Addresses** – Uses `btc3` prefix for Bech32 addresses.

## 📋 Network Parameters

| Parameter | Value |
|-----------|-------|
| **Network Port** | 13337 |
| **RPC Port** | 8332 (default) |
| **Magic Bytes** | `0xfc, 0xc1, 0xb7, 0xdc` |
| **Genesis Hash** | `0d2c382326321b1004eb676d1a8ff1a93e92bb0da7be6043a058a6edb361b89e` |
| **PoW Algorithm**| **RandomX** |
| **Genesis nBits**| `0x1f00ffff` (Hardened) |
| **Address Prefix** | `btc3` (Bech32) |
| **Block Reward** | 50 BTC3 |

## 🔧 Quick Start

### Prerequisites

- macOS, Linux, or Windows (WSL)
- CMake 3.22+
- C++17 compiler
- Boost, OpenSSL libraries

### Build from Source

```bash
# Clone the repository
git clone https://github.com/<your-username>/btc3.git
cd btc3

# Install dependencies (macOS)
brew install cmake boost openssl automake libtool

# Build
mkdir build && cd build
cmake -DENABLE_IPC=OFF -DBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
```

For detailed platform-specific instructions, see [BUILDING.md](BUILDING.md).

## Install BTC3 (Linux x86_64)

Download the prebuilt binaries:

```bash
wget https://github.com/cgebitcoin/btc3/releases/download/v30.99.0-4126e133f947/btc3-linux-x86_64.tar.gz

### Run Your First Node

```bash
# Start the daemon
./bin/btc3d -datadir=./btc3-data -server -rpcuser=admin -rpcpassword=admin -fallbackfee=0.00001 -daemon

# Create a wallet
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin createwallet "miner"

# Generate a receiving address
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getnewaddress "mining"

# Mine 101 blocks (first 100 must mature before spending)
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin generatetoaddress 101 <YOUR_ADDRESS>

# Check your balance
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin getbalance "*"
```

## ⛏️ Mining

Mining BTC3 utilizes RandomX, meaning it is most efficient on modern CPUs. No specialized ASIC hardware is required. See [MINING.md](MINING.md) for:
- Continuous mining scripts
- Solo and Pool mining setup
- RandomX performance tuning

## 🌐 Join the Network

To connect to existing BTC3 nodes:

```bash
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin addnode "seed.btc3.mrio.xyz:13337" "add"
```

For complete network participation guide, see [JOINING.md](JOINING.md).

## 📚 Documentation

- [Consensus Specification](consensus.md) – Authoritative technical rules and parameters
- [RandomX Guide](RANDOMX.md) – Details on the PoW implementation
- [Building Guide](BUILDING.md) – Platform-specific build instructions
- [Mining Guide](MINING.md) – How to mine BTC3
- [Network Guide](JOINING.md) – Join and participate in the network
- [RPC Reference](RPC.md) – Common RPC commands and examples

## 🎯 Use Cases

- **Digital Currency** – Fast, secure peer-to-peer transactions
- **Store of Value** – Decentralized cryptocurrency with proven Bitcoin technology
- **Mining** – Participate in network security and earn BTC3 rewards
- **Development** – Build applications, wallets, and services on BTC3
- **Education** – Learn blockchain technology with a real, functioning network
- **Community Projects** – Create token economies, gaming currencies, or community rewards

## 🔐 Security

BTC3 uses the same cryptographic security as Bitcoin Core, enhanced with ASIC-resistant PoW:
- **RandomX** proof-of-work (ASIC-resistant, CPU-hard)
- **LWMA** Per-block difficulty adjustment
- ECDSA signatures
- SegWit transaction format
- Full blockchain validation

The production difficulty baseline is hardened to prevent "instamine" attacks while ensuring individual miners can contribute to network security from day one.

## ⚖️ Legal Disclaimer

**IMPORTANT**: BTC3 is experimental open-source software with no warranties or guarantees. Cryptocurrency involves significant risk, and you may lose everything. 

**Before using BTC3, please read [LEGAL.md](LEGAL.md) carefully.**

Key points:
- No intrinsic value - BTC3 may be worth nothing
- Use at your own risk - no liability for losses
- Comply with your local laws - you are responsible
- Not financial advice - consult professionals
- Irreversible transactions - mistakes are permanent

By using BTC3, you acknowledge and accept all risks.

## 📄 License

BTC3 is released under the MIT License, the same as Bitcoin Core. See [COPYING](COPYING) for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## 📞 Support

- GitHub Issues: Report bugs or request features
- Discord: Join our community

## 🙏 Acknowledgments

BTC3 is built on the foundation of [Bitcoin Core](https://github.com/bitcoin/bitcoin). We thank all Bitcoin Core contributors for their incredible work.

---

**BTC3: Cryptocurrency for the people, by the people. Join us in taking back financial freedom from the elites.**

**Mine, transact, and be part of a fairer financial future. Everyone is welcome. Everyone starts equal.**

