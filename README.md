# BTC3 – The Next Generation Cryptocurrency

**BTC3** is an independent cryptocurrency built on Bitcoin Core technology, designed for accessibility and modern blockchain features. It provides a fully functional, production-ready blockchain with instant mining accessibility, making cryptocurrency participation available to everyone.

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

- **Accessible Mining** – CPU-mineable with optimized difficulty; anyone can participate in securing the network
- **Modern from Day 1** – SegWit, CSV, and all major soft forks active from block 1
- **Independent Network** – Runs on port 13337 with unique magic bytes (`0xfc,0xc1,0xb7,0xdc`)
- **Full Bitcoin Compatibility** – All RPC commands work exactly as in Bitcoin Core
- **Fair Distribution** – No premine, no ICO, pure proof-of-work from genesis
- **Recognizable Addresses** – Uses `btc3` prefix for Bech32 addresses

## 📋 Network Parameters

| Parameter | Value |
|-----------|-------|
| **Network Port** | 13337 |
| **RPC Port** | 8332 (default) |
| **Magic Bytes** | `0xfc, 0xc1, 0xb7, 0xdc` |
| **Genesis Hash** | `434a893e75eda7725c9ff1e08aa3e670cafeaf6c50dfd23036d06a1cddc9d459` |
| **Address Prefix** | `btc3` (Bech32) |
| **Block Reward** | 50 BTC3 |
| **Difficulty** | Minimal (instant mining) |

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

Mining BTC3 is instant and requires no special hardware. See [MINING.md](MINING.md) for:
- Continuous mining scripts
- Mining pool setup
- Automated mining strategies

## 🌐 Join the Network

To connect to existing BTC3 nodes:

```bash
./bin/btc3-cli -datadir=./btc3-data -rpcuser=admin -rpcpassword=admin addnode "<SEED_NODE_IP>:13337" "add"
```

For complete network participation guide, see [JOINING.md](JOINING.md).

## 📚 Documentation

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

BTC3 uses the same cryptographic security as Bitcoin Core, including:
- SHA-256 proof-of-work
- ECDSA signatures
- SegWit transaction format
- Full blockchain validation

The accessible mining difficulty is a feature designed to enable broad participation in network security, not a weakness. As the network grows, the community can propose difficulty adjustments through consensus.

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
- Discussions: Ask questions and share ideas

## 🙏 Acknowledgments

BTC3 is built on the foundation of [Bitcoin Core](https://github.com/bitcoin/bitcoin). We thank all Bitcoin Core contributors for their incredible work.

---

**BTC3: Cryptocurrency for the people, by the people. Join us in taking back financial freedom from the elites.**

**Mine, transact, and be part of a fairer financial future. Everyone is welcome. Everyone starts equal.**

