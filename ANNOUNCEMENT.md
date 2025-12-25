# BTC3 Launch Announcement

**Subject**: Introducing BTC3 – A Fast, Developer-Friendly Bitcoin Testnet

---

## 🚀 Announcing BTC3

I'm excited to share **BTC3**, a lightweight Bitcoin Core fork designed for instant mining, rapid prototyping, and educational purposes.

### What is BTC3?

BTC3 is a sandbox-style Bitcoin testnet that provides a fully functional blockchain environment while eliminating the practical constraints of the public Bitcoin network. It's perfect for developers, educators, and anyone who wants to experiment with Bitcoin without the overhead of real mining difficulty or network latency.

### ✨ Key Features

- **Instant Mining** – CPU-mineable with trivial difficulty; generate blocks in milliseconds
- **Modern from Day 1** – SegWit, CSV, and all major soft forks active from block 1
- **Isolated Network** – Runs on port 13337 with unique magic bytes
- **Full Bitcoin Compatibility** – All RPC commands work exactly as in Bitcoin Core
- **Developer Friendly** – Perfect for testing, education, and experimentation
- **Easy Setup** – Docker support, pre-built binaries, comprehensive documentation

### 🎯 Use Cases

- **Education** – Teach blockchain concepts with instant feedback
- **Development** – Test wallet software, explorers, and applications
- **Research** – Experiment with consensus rules and network behavior
- **Prototyping** – Build proof-of-concepts without mainnet constraints

### 📦 Get Started

```bash
# Clone the repository
git clone https://github.com/<your-username>/btc3.git
cd btc3

# Build (or download pre-built binaries)
mkdir build && cd build
cmake -DENABLE_IPC=OFF -DBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)

# Run your first node
./bin/btc3d -datadir=./btc3-data -daemon
./bin/btc3-cli -datadir=./btc3-data createwallet "miner"
./bin/btc3-cli -datadir=./btc3-data generatetoaddress 101 $(./bin/btc3-cli -datadir=./btc3-data getnewaddress)
```

### 📚 Documentation

- [README](https://github.com/<your-username>/btc3/blob/main/README.md) – Quick start guide
- [Building Guide](https://github.com/<your-username>/btc3/blob/main/BUILDING.md) – Platform-specific instructions
- [Mining Guide](https://github.com/<your-username>/btc3/blob/main/MINING.md) – How to mine BTC3
- [Network Guide](https://github.com/<your-username>/btc3/blob/main/JOINING.md) – Join the network
- [RPC Reference](https://github.com/<your-username>/btc3/blob/main/RPC.md) – Command reference

### 🌐 Network Parameters

| Parameter | Value |
|-----------|-------|
| Network Port | 13337 |
| Magic Bytes | 0xfc, 0xc1, 0xb7, 0xdc |
| Address Prefix | btc3 (Bech32) |
| Block Reward | 50 BTC3 |
| Difficulty | Minimal (instant mining) |

### 🤝 Join the Network

Connect to the seed node at `<YOUR_IP>:13337` to start participating:

```bash
./bin/btc3-cli addnode "<SEED_IP>:13337" "add"
```

### 📄 License

BTC3 is released under the MIT License, the same as Bitcoin Core.

### 🙏 Acknowledgments

BTC3 is built on the foundation of Bitcoin Core. Special thanks to all Bitcoin Core contributors.

---

**Links:**
- GitHub: https://github.com/<your-username>/btc3
- Releases: https://github.com/<your-username>/btc3/releases
- Issues: https://github.com/<your-username>/btc3/issues

**Start mining BTC3 today and experience Bitcoin development without limits!**

---

## Social Media Posts

### Twitter/X

🚀 Introducing BTC3 – a fast, developer-friendly Bitcoin testnet!

✨ Features:
• Instant CPU mining
• SegWit active from block 1
• Full Bitcoin Core compatibility
• Perfect for testing & education

Get started: https://github.com/<your-username>/btc3

#Bitcoin #Blockchain #Crypto #BTC3

### Reddit (r/Bitcoin, r/BitcoinDev)

**Title**: [Project] BTC3 – A Fast Bitcoin Testnet for Development and Education

I've created BTC3, a lightweight Bitcoin Core fork designed for instant mining and rapid prototyping. It's perfect for developers who want to test Bitcoin-compatible software without the overhead of real mining difficulty.

**Key features:**
- Instant CPU mining (trivial difficulty)
- SegWit and all modern features active from block 1
- Isolated network (port 13337, unique magic bytes)
- Full RPC compatibility with Bitcoin Core
- Docker support and comprehensive documentation

**Use cases:**
- Testing wallet software and explorers
- Teaching blockchain concepts
- Prototyping new features
- Research and experimentation

Check it out: https://github.com/<your-username>/btc3

Feedback and contributions welcome!

### Hacker News

**Title**: BTC3 – A Fast, Self-Contained Bitcoin Testnet

**Description**: BTC3 is a lightweight Bitcoin Core fork with trivial mining difficulty, making it perfect for development, testing, and education. All modern Bitcoin features (SegWit, CSV, etc.) are active from block 1, and it runs on an isolated network with full RPC compatibility.

Link: https://github.com/<your-username>/btc3

---

## Email Template (for Bitcoin mailing lists)

Subject: [ANN] BTC3 – A Developer-Friendly Bitcoin Testnet

Hi everyone,

I'd like to introduce BTC3, a Bitcoin Core fork optimized for development and education.

**What makes BTC3 different:**

BTC3 uses a trivial proof-of-work difficulty, allowing instant block generation on any CPU. This makes it ideal for:
- Testing Bitcoin-compatible software
- Teaching blockchain concepts
- Rapid prototyping
- Network simulations

All modern consensus rules (SegWit, CSV, BIP34/65/66) are active from the genesis block, providing a fully modern chain from the start.

**Technical details:**
- Based on Bitcoin Core 0.30.99
- Custom genesis block
- Network port: 13337
- Bech32 address prefix: btc3
- Full RPC compatibility
- MIT licensed

**Getting started:**
https://github.com/<your-username>/btc3

Documentation includes building guides, mining instructions, and network participation details.

I'm looking for feedback and contributions. Feel free to open issues or submit PRs.

Thanks,
[Your Name]

---

## Forum Post Template (BitcoinTalk)

**[ANN] BTC3 – Instant Mining Bitcoin Testnet**

**What is BTC3?**

BTC3 is a Bitcoin Core fork designed for developers, educators, and researchers. It provides a fully functional blockchain with instant mining, making it perfect for testing and experimentation.

**Features:**
✓ Instant CPU mining (trivial difficulty)
✓ SegWit active from block 1
✓ Full Bitcoin Core RPC compatibility
✓ Isolated network (port 13337)
✓ Docker support
✓ Comprehensive documentation

**Use Cases:**
• Test wallet software and explorers
• Teach blockchain development
• Prototype new features
• Research consensus mechanisms

**Network Parameters:**
• Port: 13337
• Magic Bytes: 0xfc, 0xc1, 0xb7, 0xdc
• Address Prefix: btc3
• Block Reward: 50 BTC3

**Links:**
GitHub: https://github.com/<your-username>/btc3
Documentation: https://github.com/<your-username>/btc3#readme
Releases: https://github.com/<your-username>/btc3/releases

**Seed Node:**
Connect to: <YOUR_IP>:13337

Join the network and start mining today!

