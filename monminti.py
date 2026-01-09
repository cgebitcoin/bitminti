import http.server
import json
import requests
import struct
import binascii
import time
import hashlib

# --- CONFIGURATION ---
BITCOIN_RPC_URL = "http://127.0.0.1:18332"
# Note: On server, ensure this points to the Docker container IP or mapped port
# BITCOIN_RPC_URL = "http://172.18.0.x:18332" 
BITCOIN_USER = "pooluser"
BITCOIN_PASS = "poolpass"
PROXY_PORT = 18081
PAYOUT_ADDR = "12PfKdf1JgykKMZ7yeHBSUqujfjPF4DFhg" 
# ---------------------

def decode_base58(bc, length):
    digits = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = 0
    for char in bc: n = n * 58 + digits.index(char)
    return n.to_bytes(25, 'big')[-24:]

def address_to_pkh(addr):
    # Simplified Base58 Check Decode
    return decode_base58(addr, 25)[1:21]

def dsha256(data): 
    return hashlib.sha256(hashlib.sha256(data).digest()).digest()

def merkle_root_calc(tx_hashes):
    # Hashes should be in RAW bytes (Little Endian as needed for computation, usually internal is BE/LE consistency matters)
    # Merkle Tree matches Bitcoin Standard
    if len(tx_hashes) == 0: return b'\x00'*32
    while len(tx_hashes) > 1:
        if len(tx_hashes) % 2 != 0: tx_hashes.append(tx_hashes[-1])
        new_hashes = []
        for i in range(0, len(tx_hashes), 2):
            new_hashes.append(dsha256(tx_hashes[i] + tx_hashes[i+1]))
        tx_hashes = new_hashes
    return tx_hashes[0]

def create_coinbase(height, value, pkh):
    # BIP34: Height in ScriptSig
    # Height of 120 -> \x78
    if height < 256:
        script_height = b'\x01' + bytes([height])
    else:
        script_height = b'\x03' + struct.pack("<I", height)[:3]
        
    script_sig = script_height + b'ProxyMined'
    
    # Input
    vin = b'\x00'*32 + b'\xff\xff\xff\xff' + bytes([len(script_sig)]) + script_sig + b'\xff\xff\xff\xff'
    
    # Output
    script_pub = b'\x76\xa9\x14' + pkh + b'\x88\xac'
    vout = struct.pack("<Q", value) + bytes([len(script_pub)]) + script_pub
    
    # Tx Version 1, Locktime 0
    tx = struct.pack("<I", 1) + b'\x01' + vin + b'\x01' + vout + b'\x00\x00\x00\x00'
    return tx, dsha256(tx)

def rpc(method, params=[]):
    payload = {"jsonrpc": "1.0", "id": "proxy", "method": method, "params": params}
    try:
        resp = requests.post(BITCOIN_RPC_URL, json=payload, auth=(BITCOIN_USER, BITCOIN_PASS))
        if resp.status_code != 200:
            print(f"RPC Error {resp.status_code}")
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
            
            if method in ['get_block_template', 'getblocktemplate']:
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
        epoch_height = (height // 2048) * 2048
        # If epoch_height is 0, genesis.
        try:
            h = rpc("getblockhash", [epoch_height])
            return h
        except:
            return "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"

    def handle_get_info(self, req):
         self.send_json({ "jsonrpc": "2.0", "id": req.get('id'), "result": { "status": "OK", "height": 100, "difficulty": 100, "mainnet": True }})

    def handle_get_block_template(self, req):
        btc_tmpl = rpc("getblocktemplate", [{"rules":["segwit"], "capabilities":["coinbasetxn", "workid", "coinbase/append"]}])
        if not btc_tmpl:
            self.send_json({"error": {"code": -1, "message": "RPC Broken"}})
            return

        # Header Construction
        ver = struct.pack("<I", btc_tmpl['version'])
        prev = binascii.unhexlify(btc_tmpl['previousblockhash'])[::-1]
        
        # Merkle Root Logic
        if 'coinbasetxn' in btc_tmpl:
             root = binascii.unhexlify(btc_tmpl['coinbasetxn']['hash'])[::-1]
        else:
             # Manual Construction
             height = btc_tmpl['height']
             val = btc_tmpl['coinbasevalue']
             try:
                 pkh = address_to_pkh(PAYOUT_ADDR)
             except:
                 pkh = b'\x00'*20 # Fallback
             
             # Create Coinbase
             cb_tx, cb_hash = create_coinbase(height, val, pkh)
             
             # Aggregate other txns
             tx_hashes = [cb_hash]
             for tx in btc_tmpl['transactions']:
                  tx_hashes.append(binascii.unhexlify(tx['hash'])[::-1]) # Little Endian
             
             root = merkle_root_calc(tx_hashes)

        ts = struct.pack("<I", btc_tmpl['curtime'])
        bits = struct.pack("<I", int(btc_tmpl['bits'], 16))
        nonce = b'\x00\x00\x00\x00'

        header = ver + prev + root + ts + bits + nonce
        blob_hex = binascii.hexlify(header).decode()

        seed = self.get_seed_hash(btc_tmpl['height'])
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
                "reserved_offset": 76, 
                "status": "OK"
            }
        }
        self.send_json(resp)

    def handle_submit_block(self, req):
        blob = req.get('params')[0]
        # XMRig modified the blob (nonce).
        # We send Header to submitheader.
        # This only validates PoW not Txns, but it works for mining test.
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
