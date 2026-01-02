# How to Run a DNS Seeder for BitMinti

To make `vSeeds` (automatic discovery) work, you must run a special "DNS Crawler" program. This program crawls the P2P network, finds active nodes, and answers DNS queries with their IP addresses.

The standard tool is **sipa/bitcoin-seeder**.

## 1. DNS Configuration (Namecheap/GoDaddy/Route53)

You need to delegate a subdomain to your seeder server.
Assume your seeder server IP is `3.146.187.209`.

1.  **Create an "A" Record (Glue Record):**
    *   Host: `<NS_DOMAIN>`
    *   Value: `<YOUR_VPS_IP>`

2.  **Create a "NS" Record (Delegation):**
    *   Host: `<SEED_DOMAIN>`
    *   Value: `<NS_DOMAIN>`

**Result:** When anyone asks for `<SEED_DOMAIN>`, the request is sent to your VPS (`<YOUR_VPS_IP>`) which will answer it using the crawler software.

## 2. Server Setup (Ubuntu 20.04/22.04/24.04)

SSH into your EC2 instance (`<YOUR_VPS_IP>`):

### Step 1: Install Dependencies
```bash
sudo apt-get update
sudo apt-get install -y build-essential libboost-all-dev libssl-dev git
```

### Step 2: Clone and Build the Seeder
We use the standard Bitcoin Seeder.
```bash
git clone https://github.com/sipa/bitcoin-seeder.git
cd bitcoin-seeder
make
```

### Step 3: Stop Conflicting Services (Crucial)
Ubuntu runs a local DNS stub `systemd-resolved` on Port 53 by default. You MUST stop it, otherwise the seeder cannot bind to the port.

```bash
# 1. Stop the system service
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

# 2. Fix your server's DNS (since we just killed the local resolver)
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

### Step 4: Run the Seeder
Use `screen` or `tmux` to keep it running.
**Note:** We must explicitly use `-p 53` for DNS and `--p2port 13337` for Bitcoin.

```bash
# Start a new session
tmux new -s seeder

# Run the seeder (inside tmux)
sudo ./dnsseed -h <SEED_DOMAIN> -n <NS_DOMAIN> -m <YOUR_EMAIL> -p 53 --p2port 13337
```
*(Press `Ctrl+B`, then `D` to detach)*

## 3. Firewall Setup (AWS)
For the world to reach you, you must open the **Firewall** in AWS Console:
*   **Security Groups** -> Inbound Rules
*   **Add Rule:** Custom UDP, Port **53**, Source `0.0.0.0/0`
*   *(Optional but good)*: Custom TCP, Port 53, Source `0.0.0.0/0`

## 4. Verification

1.  **Check Local Binding:**
    ```bash
    sudo netstat -anup | grep 53
    ```
    Should show: `0.0.0.0:53` or `:::53`.

2.  **Test from another computer:**
    ```bash
    dig <SEED_DOMAIN> @<YOUR_VPS_IP>
    ```
    If it replies with an IP in the ANSWER section, you are live!
