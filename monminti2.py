import socketserver
import json
import struct
import hashlib
import time
import requests
import binascii

# ================= CONFIG =================
RPC_URL = "http://127.0.0.1:18443"
RPC_USER = "admin"
RPC_PASS = "admin"

STRATUM_PORT = 3333
SEED_EPOCH = 2048
# =========================================


# ---------- RPC ----------
def rpc(method, params=None):
    if params is None:
        params = []
    payload = {
        "jsonrpc": "1.0",
        "id": "bitminti",
        "method": method,
        "params": params
    }
    r = requests.post(RPC_URL, json=payload, auth=(RPC_USER, RPC_PASS))
    if r.status_code != 200:
        raise RuntimeError(r.text)
    return r.json()["result"]


# ---------- Helpers ----------
def dsha256(b):
    return hashlib.sha256(hashlib.sha256(b).digest()).digest()


def encode_varint(i):
    if i < 0xfd:
        return bytes([i])
    elif i <= 0xffff:
        return b'\xfd' + struct.pack('<H', i)
    elif i <= 0xffffffff:
        return b'\xfe' + struct.pack('<I', i)
    else:
        return b'\xff' + struct.pack('<Q', i)


def merkle_root(txids):
    hashes = txids[:]
    while len(hashes) > 1:
        if len(hashes) % 2 == 1:
            hashes.append(hashes[-1])
        hashes = [
            dsha256(hashes[i] + hashes[i + 1])
            for i in range(0, len(hashes), 2)
        ]
    return hashes[0]


def randomx_seed(height):
    if height < SEED_EPOCH:
        return b"\x00" * 32
    epoch = (height // SEED_EPOCH) * SEED_EPOCH
    return bytes.fromhex(rpc("getblockhash", [epoch]))


# ---------- Coinbase ----------
def build_coinbase(height, value, payout_script):
    # BIP34 height push
    height_bytes = struct.pack("<I", height).rstrip(b"\x00")
    script_sig = bytes([len(height_bytes)]) + height_bytes + b"BitMinti"

    tx = (
        struct.pack("<I", 1) +           # version
        b"\x01" +                         # input count
        b"\x00" * 32 +                   # prevout hash
        b"\xff\xff\xff\xff" +            # prevout index
        encode_varint(len(script_sig)) +
        script_sig +
        b"\xff\xff\xff\xff"              # sequence
    )

    tx += (
        b"\x01" +                        # output count
        struct.pack("<Q", value) +
        encode_varint(len(payout_script)) +
        payout_script
    )

    tx += b"\x00\x00\x00\x00"            # locktime
    return tx


# ---------- Stratum ----------
class RXHandler(socketserver.BaseRequestHandler):

    def handle(self):
        self.job = None
        self.requested_algo = None

        print(f"[+] Miner connected: {self.client_address}")

        while True:
            data = self.request.recv(4096)
            if not data:
                break

            for line in data.decode().splitlines():
                if line:
                    self.process(json.loads(line))

    def send(self, obj):
        self.request.sendall((json.dumps(obj) + "\n").encode())

    def process(self, req):
        method = req.get("method")
        msg_id = req.get("id")

        if method == "login":
            params = req.get("params", {})
            algo = params.get("algo", [])
            self.requested_algo = algo[0] if algo else None
            self.handle_login(msg_id)

        elif method == "submit":
            self.handle_submit(req, msg_id)

        elif method == "keepalived":
            self.send({"jsonrpc": "2.0", "id": msg_id, "result": {"status": "OK"}})

    # ---------- Login ----------
    def handle_login(self, msg_id):
        if self.requested_algo != "rx/0":
            self.send({
                "jsonrpc": "2.0",
                "id": msg_id,
                "error": {"code": -1, "message": "Unsupported algo"}
            })
            return

        tmpl = rpc("getblocktemplate", [{"rules": ["segwit"]}])

        self.job = {
            "template": tmpl,
            "height": tmpl["height"],
            "seed": randomx_seed(tmpl["height"])
        }

        # ===== RANDOMX HASHING BLOB (80 bytes) =====
        # (miners hash THIS, node does NOT parse this)
        prev = bytes.fromhex(tmpl["previousblockhash"])[::-1]
        dummy_merkle = b"\x00" * 32

        blob = (
            prev +
            dummy_merkle +
            struct.pack("<I", tmpl["height"]) +
            b"\x00" * 8 +
            b"\x00\x00\x00\x00"
        )

        self.send({
            "jsonrpc": "2.0",
            "id": msg_id,
            "result": {
                "id": "bitminti-session",
                "status": "OK",
                "extensions": ["algo"],
                "job": {
                    "job_id": hex(int(time.time()))[2:],
                    "blob": blob.hex(),
                    "seed_hash": self.job["seed"].hex(),
                    "target": "ffffffffffffffff",   # 64-bit target
                    "algo": "rx/0"
                }
            }
        })

        print("[JOB] Login accepted — mining started")

    # ---------- Submit ----------
    def handle_submit(self, req, msg_id):
        nonce = int(req["params"]["nonce"], 16)
        tmpl = self.job["template"]

        # ----- Build coinbase -----
        payout_script = bytes.fromhex(
            "76a914" + "00"*20 + "88ac"   # ANY valid P2PKH (dev only)
        )

        coinbase = build_coinbase(
            tmpl["height"],
            tmpl["coinbasevalue"],
            payout_script
        )

        coinbase_hash = dsha256(coinbase)

        # ----- Merkle root -----
        tx_hashes = [coinbase_hash]
        for tx in tmpl["transactions"]:
            tx_hashes.append(bytes.fromhex(tx["hash"]))

        merkle = merkle_root(tx_hashes)

        # ----- Bitcoin block header -----
        header = (
            struct.pack("<I", tmpl["version"]) +
            bytes.fromhex(tmpl["previousblockhash"])[::-1] +
            merkle +
            struct.pack("<I", tmpl["curtime"]) +
            bytes.fromhex(tmpl["bits"])[::-1] +
            struct.pack("<I", nonce)
        )

        # ----- Full block -----
        block = (
            header +
            encode_varint(1 + len(tmpl["transactions"])) +
            coinbase +
            b"".join(bytes.fromhex(tx["data"]) for tx in tmpl["transactions"])
        )

        print("[SUBMIT] Full block built, submitting to node")

        res = rpc("submitblock", [block.hex()])
        print("[NODE] submitblock:", res)

        self.send({
            "jsonrpc": "2.0",
            "id": msg_id,
            "result": {"status": "OK"}
        })


class ThreadedServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True


if __name__ == "__main__":
    print(f"[BitMinti] RandomX Stratum FULL proxy on port {STRATUM_PORT}")
    with ThreadedServer(("0.0.0.0", STRATUM_PORT), RXHandler) as server:
        server.serve_forever()

