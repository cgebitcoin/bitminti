# BitMinti Mining Pool Server

This folder contains a complete, self-hosted mining pool stack using **Miningcore**.

## 🛠️ Prerequisites
*   Docker & Docker Compose installed on your server.
*   A valid BitMinti wallet address (to receive pool fees/rewards).

## 🚀 Setup & Run

1.  **Configure Wallet:**
    Edit `config.json` and replace `YOUR_POOL_WALLET_ADDRESS_HERE` with your actual BM address.

2.  **Start the Stack:**
    ```bash
    docker-compose up -d
    ```
    *This automatically configures Huge Pages (Fast Mode) for the node!*

3.  **Initialize Database (First Run Only):**
    ```bash
    ./init-db.sh
    ```

4.  **Verify:**
    Check logs to ensure it's running:
    ```bash
    docker-compose logs -f miningcore
    ```

## 🔌 Ports
*   **3032:** Stratum (Low Diff / CPU) - Connect miners here!
*   **3033:** Stratum (High Diff / Rigs)
*   **4000:** API (for your Pool UI / Dashboard)
*   **13337:** BitMinti P2P Network

## 🛡️ Security Note
The RPC port (18332) is isolated inside the Docker network. It is NOT exposed to the internet.
User `pooluser` / Pass `poolpass` is used internally between the pool and the node.
