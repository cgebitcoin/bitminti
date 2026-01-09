import http.server
import json
import requests
import struct
import binascii
import time

# --- CONFIGURATION ---
# BitMinti RPC Credentials
BITCOIN_RPC_URL = "http://127.0.0.1:18332"
BITCOIN_USER = "pooluser"
BITCOIN_PASS = "poolpass"
PROXY_PORT = 18081
# ---------------------

def rpc(method, params=[]):
    payload = {"jsonrpc": "1.0", "id": "proxy", "method": method, "params": params}
    try:
        resp = requests.post(BITCOIN_RPC_URL, json=payload, auth=(BITCOIN_USER, BITCOIN_PASS))
        if resp.status_code != 200:
            print(f"RPC Error {resp.status_code}: {resp.text}")
            return None
        return resp.json()['result']
    except Exception as e:
        print(f"Error calling Bitcoin RPC: {e}")
        return None

class MoneroHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        content_len = int(self.headers.get('Content-Length', 0))
        post_body = self.rfile.read(content_len)
        try:
            req = json.loads(post_body)
            method = req.get('method')
            
            if method == 'get_block_template' or method == 'getblocktemplate':
                self.handle_get_block_template(req)
            elif method == 'submit_block':
                self.handle_submit_block(req)
            elif method == 'get_info':
                self.handle_get_info(req)
            else:
                self.send_error(404, "Method not implemented")
        except Exception as e:
            print(f"Handler Exception: {e}")
            self.send_error(500)

    def send_json(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def get_seed_hash(self, height):
        # BitMinti Epoch Logic: 2048 blocks
        epoch_start = (height // 2048) * 2048
        # Get hash of that block
        return rpc("getblockhash", [epoch_start])

    def handle_get_info(self, req):
         # Dummy info for XMRig connectivity
         self.send_json({
             "jsonrpc": "2.0",
             "id": req.get('id'),
             "result": {
                 "status": "OK",
                 "height": 100,
                 "difficulty": 1000,
                 "target_height": 100,
                 "mainnet": True
             }
         })

    def handle_get_block_template(self, req):
        # 1. Get Bitcoin Template
        # We need 'coinbasetxn' capability to ensure daemon builds the coinbase
        # Otherwise the header merkle root will be empty/invalid
        btc_tmpl = rpc("getblocktemplate", [{"rules":["segwit"], "capabilities":["coinbasetxn", "workid", "coinbase/append"]}])
        
        if not btc_tmpl:
            self.send_json({"error": {"code": -1, "message": "RPC Broken"}})
            return

        # 2. Extract Header Data (80 Bytes, Little Endian)
        ver = struct.pack("<I", btc_tmpl['version'])
        prev = binascii.unhexlify(btc_tmpl['previousblockhash'])[::-1]
        
        # Merkle Root
        if 'coinbasetxn' in btc_tmpl:
             root = binascii.unhexlify(btc_tmpl['coinbasetxn']['hash'])[::-1]
        else:
             # Fallback if mining not ready (no wallet/address)
             # We send dummy root so XMRig can at least start (mining will be invalid)
             root = b'\x00'*32
             print("WARNING: coinbasetxn missing. Mining invalid blocks.")

        ts = struct.pack("<I", btc_tmpl['curtime'])
        bits = struct.pack("<I", int(btc_tmpl['bits'], 16))
        nonce = b'\x00\x00\x00\x00' # Default 0

        header = ver + prev + root + ts + bits + nonce
        blob_hex = binascii.hexlify(header).decode()

        # Seed Hash
        seed = self.get_seed_hash(btc_tmpl['height'])
        
        # Difficulty (Approx conversion Target -> Diff)
        target_int = int(btc_tmpl['target'], 16)
        diff = (2**256 - 1) // target_int

        resp = {
            "jsonrpc": "2.0",
            "id": req.get('id'),
            "result": {
                "blocktemplate_blob": blob_hex,
                "difficulty": diff,
                "height": btc_tmpl['height'],
                "seed_hash": seed,
                "reserved_offset": 76, # Point XMRig to Nonce offset (76-80)
                "status": "OK"
            }
        }
        self.send_json(resp)

    def handle_submit_block(self, req):
        # Params: [blob_hex]
        # XMRig submits the modified 80-byte header
        blob = req.get('params')[0]
        print(f"Submitting Header: {blob[:64]}...")
        
        # We use submitheader to validate PoW
        res = rpc("submitheader", [blob])
        
        if res is None:
             print("Header Accepted!")
             self.send_json({"jsonrpc": "2.0", "id": req.get('id'), "result": {"status": "OK"}})
        else:
             print(f"Header Rejected: {res}")
             self.send_json({"jsonrpc": "2.0", "id": req.get('id'), "result": {"status": "Error"}})

if __name__ == "__main__":
    print(f"Monero-BitMinti Proxy listening on {PROXY_PORT}")
    http.server.HTTPServer(('0.0.0.0', PROXY_PORT), MoneroHandler).serve_forever()
