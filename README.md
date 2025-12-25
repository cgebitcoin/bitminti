# BTC3 – The Next Generation Bitcoin Testnet

**BTC3** is a lightweight, sandbox-style fork of Bitcoin Core designed for instant mining, rapid prototyping, and educational purposes. It provides a fully functional blockchain environment while eliminating the practical constraints of the public Bitcoin network.

## 🚀 Key Features

- **Instant Mining** – CPU-mineable with trivial difficulty; generate blocks in milliseconds
- **Modern from Day 1** – SegWit, CSV, and all major soft forks active from block 1
- **Isolated Network** – Runs on port 13337 with unique magic bytes (`0xfc,0xc1,0xb7,0xdc`)
- **Full Bitcoin Compatibility** – All RPC commands work exactly as in Bitcoin Core
- **Developer Friendly** – Perfect for testing, education, and experimentation
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

- **Education** – Teach blockchain concepts with instant feedback
- **Development** – Test wallet software, explorers, and applications
- **Research** – Experiment with consensus rules and network behavior
- **Prototyping** – Build proof-of-concepts without mainnet constraints
- **Testing** – Validate Bitcoin-compatible software in a controlled environment

## 🔐 Security Note

BTC3 is designed for **testing and development only**. The trivial mining difficulty means it has no security against attacks. Do not use it for storing real value.

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

**Start mining BTC3 today and experience Bitcoin development without limits!**

