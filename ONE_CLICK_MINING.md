# One-Click Mining Guide

Start mining BitMinti with a single command!

## 🪟 Windows

1. **Download** the latest Windows release from:
   ```
   https://github.com/cgebitcoin/bitminti/releases
   ```

2. **Extract** the zip file to a folder

3. **Double-click** `mine-windows.bat`

That's it! Mining will start automatically.

### What it does:
- ✅ Creates a wallet automatically
- ✅ Generates a mining address
- ✅ Starts the daemon
- ✅ Begins mining with all CPU cores
- ✅ Shows mining progress in the console

### To stop:
Press `Ctrl+C` in the console window.

---

## 🐧 Linux

1. **Download** or build BitMinti:
   ```bash
   git clone https://github.com/cgebitcoin/bitminti.git
   cd bitminti
   cmake -B build -DBUILD_GUI=OFF
   cmake --build build -j$(nproc)
   ```

2. **Run** the one-click miner:
   ```bash
   ./mine-linux.sh
   ```

That's it! Mining will start automatically.

### What it does:
- ✅ Creates `~/.bitminti` data directory
- ✅ Creates a wallet automatically
- ✅ Generates a mining address
- ✅ Starts the daemon with Fast Mode enabled
- ✅ Begins continuous mining

### To stop:
Press `Ctrl+C` in the terminal.

---

## 📊 Checking Your Balance

### Windows:
```cmd
bitminti-cli.exe getbalance
```

### Linux:
```bash
./build/bin/bitminti-cli getbalance
```

**Note:** Mined coins need 100 confirmations before they become spendable. This takes about 100 minutes (100 blocks × 1 minute per block).

---

## ⚙️ Advanced Options

### Mining to a Specific Address

If you want to mine to an existing address:

**Windows:**
```cmd
bitminti-cli.exe -rpcwallet=miner generatetoaddress 1000 YOUR_ADDRESS_HERE 1000000
```

**Linux:**
```bash
./build/bin/bitminti-cli -rpcwallet=miner generatetoaddress 1000 YOUR_ADDRESS_HERE 1000000
```

### Checking Mining Performance

**Windows:**
```cmd
bitminti-cli.exe getmininginfo
```

**Linux:**
```bash
./build/bin/bitminti-cli getmininginfo
```

Look for `"networkhashps"` to see the total network hashrate.

---

## 🔧 Troubleshooting

### "Daemon not responding"
Wait 10-15 seconds for the daemon to fully start, then try again.

### "Could not generate mining address"
Make sure the daemon is running:
```bash
# Linux
pgrep bitmintid

# Windows (in cmd)
tasklist | findstr bitmintid
```

### Low hashrate
Make sure Fast Mode is enabled. You should see this in the logs:
```
RandomX: dataset allocated (2080 MB)
```

If you don't see this, your system may not have enough RAM or huge pages aren't enabled.

---

## 💡 Tips for Best Performance

1. **Close other programs** while mining
2. **Enable Fast Mode** (already enabled in one-click scripts)
3. **Use a modern CPU** with AES-NI support
4. **Ensure adequate cooling** - CPU mining generates heat!

---

## 🌐 Join the Community

- **Website:** https://bitminti.com
- **GitHub:** https://github.com/cgebitcoin/bitminti
- **Reddit:** r/BitMinti

Happy Mining! ⛏️
