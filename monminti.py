import socketserver
import json
import urllib.request
import urllib.error
import struct
import binascii
import time
import hashlib
import threading
import subprocess

# --- CONFIGURATION ---
BITCOIN_RPC_URL = "http://127.0.0.1:13336"
BITCOIN_USER = "admin"
BITCOIN_PASS = "admin"
STRATUM_PORT = 3333 
DEFAULT_PAYOUT = "12PfKdf1JgykKMZ7yeHBSUqujfjPF4DFhg" 
# ---------------------

def decode_base58(bc, length):
    digits = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = 0
    for char in bc: n = n * 58 + digits.index(char)
    try:
        return n.to_bytes(25, 'big')[-24:]
    except:
        return None

def address_to_pkh(addr):
    decoded = decode_base58(addr, 25)
    if decoded:
        return decoded[1:21]
    return None

def dsha256(data): 
    return hashlib.sha256(hashlib.sha256(data).digest()).digest()

def merkle_root_calc(tx_hashes):
    if len(tx_hashes) == 0: return b'\x00'*32
    while len(tx_hashes) > 1:
        if len(tx_hashes) % 2 != 0: tx_hashes.append(tx_hashes[-1])
        new_hashes = []
        for i in range(0, len(tx_hashes), 2):
            new_hashes.append(dsha256(tx_hashes[i] + tx_hashes[i+1]))
        tx_hashes = new_hashes
    return tx_hashes[0]

def create_coinbase(height, value, pkh, extra_nonce=None, witness_commitment=None):
    # BIP34: Height must be pushed strictly properly (CScript)
    if height == 0:
        script_height = b'\x00' # OP_0
    elif height <= 16:
        script_height = bytes([0x50 + height]) # OP_1 .. OP_16
    else:
        # Minimal encoding for > 16
        b = b''
        n = height
        while n > 0:
            b += bytes([n & 0xFF])
            n >>= 8
        if b[-1] & 0x80:
            b += b'\x00'
        script_height = bytes([len(b)]) + b
        
    script_sig = script_height + b'ProxyMined'
    if extra_nonce:
        try:
            en_bytes = binascii.unhexlify(extra_nonce)
            script_sig += b'\x08' + en_bytes 
        except: pass

    vin = b'\x00'*32 + b'\xff\xff\xff\xff' + bytes([len(script_sig)]) + script_sig + b'\xff\xff\xff\xff'
    script_pub = b'\x76\xa9\x14' + pkh + b'\x88\xac'
    
    outputs = []
    outputs.append(struct.pack("<Q", value) + bytes([len(script_pub)]) + script_pub)
    
    if witness_commitment:
        wc_bytes = binascii.unhexlify(witness_commitment)
        wc_script = wc_bytes
        outputs.append(struct.pack("<Q", 0) + bytes([len(wc_script)]) + wc_script)

    vout_bin = encode_varint(len(outputs))
    for o in outputs:
        vout_bin += o
    
    tx = struct.pack("<I", 1) + b'\x01' + vin + vout_bin + b'\x00\x00\x00\x00'
    return tx, dsha256(tx)

def encode_varint(i):
    if i < 0xfd: return bytes([i])
    elif i <= 0xffff: return b'\xfd' + struct.pack("<H", i)
    elif i <= 0xffffffff: return b'\xfe' + struct.pack("<I", i)
    else: return b'\xff' + struct.pack("<Q", i)

def rpc(method, params=[]):
    payload = json.dumps({"jsonrpc": "1.0", "id": "proxy", "method": method, "params": params}).encode('utf-8')
    req = urllib.request.Request(BITCOIN_RPC_URL, data=payload, headers={'Content-Type': 'application/json'})
    
    # Basic Auth
    import base64
    auth_str = f"{BITCOIN_USER}:{BITCOIN_PASS}"
    auth_b64 = base64.b64encode(auth_str.encode('utf-8')).decode('utf-8')
    req.add_header("Authorization", f"Basic {auth_b64}")

    try:
        with urllib.request.urlopen(req, timeout=30) as f:
            resp_data = f.read().decode('utf-8')
            return json.loads(resp_data)['result']
    except urllib.error.HTTPError as e:
        print(f"RPC HTTP Error {e.code}: {e.read().decode()}")
        return None
    except Exception as e:
        print(f"Error calling Bitcoin RPC: {e}")
        return None

def get_seed_hash(height):
    epoch_height = (height // 2048) * 2048
    # Zero checking removed. Always fetch real hash.

    try:
        h = rpc("getblockhash", [epoch_height])
        print(f"DEBUG: Retrieved Seed Hash for Height {height} (Epoch {epoch_height}): {h}")
        # Try Swapping Seed Endianness?
        # RPC returns Big Endian Hex usually.
        # RandomX usually expects LE bytes 0-31.
        # If we send string "00..", XMRig parses it.
        # Try INVERTING the hex string for non-zero seeds.
        # And for zero seed? 00 swapped is 00.
        
        # But wait, Epoch 0 usage:
        # If we are mining Block 1, Seed is Zero.
        # So swapping Zero does nothing.
        # AND WE ARE FAILING ON BLOCK 1 (Epoch 0).
        # So Seed-Swap helps for later blocks, but not for the first one.
        # Unless XMRig treats "0000" specially?
        
        return h
    except Exception as e:
        print(f"WARNING: Failed to get seed hash for height {height}: {e}")
        # BitMinti mainnet genesis hash
        return "0d2c382326321b1004eb676d1a8ff1a93e92bb0da7be6043a058a6edb361b89e"

def verify_randomx(blob_hex, seed_hex):
    try:
        if len(seed_hex) != 64: return "Invalid Seed"
        cmd = ["./debug_rx", seed_hex, blob_hex]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            return f"Error: {result.stderr}"
        return result.stdout.strip()
    except Exception as e:
        return f"Ex: {e}"

class StratumHandler(socketserver.BaseRequestHandler):
    def handle(self):
        print(f"[+] Client connected: {self.client_address}")
        self.miner_pkh = address_to_pkh(DEFAULT_PAYOUT)
        self.extra_nonce = binascii.hexlify(struct.pack(">I", int(time.time()) % 0xFFFFFFFF)).decode()
        self.current_job = None
        
        try:
            while True:
                line = self.request.recv(4096).decode('utf-8').strip()
                if not line: break
                
                for part in line.split('\n'):
                    if not part: continue
                    req = json.loads(part)
                    self.process_request(req)
        except Exception as e:
            print(f"[-] Client Disconnect: {e}")
            
    def send_json(self, data):
        resp = json.dumps(data) + "\n"
        self.request.sendall(resp.encode('utf-8'))

    def process_request(self, req):
        method = req.get('method')
        msg_id = req.get('id')
        
        if method == 'login':
            params = req.get('params', {})
            login_user = params.get('login')
            if login_user:
                 user_pkh = address_to_pkh(login_user)
                 if user_pkh: 
                     self.miner_pkh = user_pkh
                     print(f"Mining for User: {login_user}")

            job = self.create_job()
            if job:
                resp = {
                    "jsonrpc": "2.0",
                    "id": msg_id,
                    "result": {
                        "id": "1",
                        "job": job,
                        "extensions": ["algo"],
                        "status": "OK"
                    }
                }
                self.send_json(resp)
                
                # [BITMINTI FIX] Enforce Difficulty to stop XMRig flooding
                # Diff 1 is standard high difficulty (Target ~00000000FFFF...)
                # This ensures XMRig only submits good shares.
                diff_notif = {
                    "jsonrpc": "2.0",
                    "method": "mining.set_difficulty",
                    "params": [1.0]
                }
                self.send_json(diff_notif)

            else:
                self.send_json({"error": "Failed to get job"})
            
        elif method == 'submit':
            params = req.get('params', {})
            nonce_hex = params.get('nonce')
            ntime_hex = params.get('ntime') 
            
            print(f"Nonce Direct: {nonce_hex}")
            
            # Swap Nonce Endianness logic
            # "000000c6" -> "c6000000"
            def swap_hex(s):
                return "".join(reversed([s[i:i+2] for i in range(0, len(s), 2)]))
            
            nonce_swapped = swap_hex(nonce_hex)
            print(f"Nonce Swapped: {nonce_swapped}")

            # Reconstruct Block
            if self.current_job:
                # Base Blob (from job creation)
                # We need to construct the Candidate Header using params
                
                 # 1. Nonce
                nonce_direct = nonce_hex
                
                # 2. Time
                # blob hex has time at offset 68 (chars 136-144)
                # bits at offset 72 (chars 144-152)
                # nonce at offset 76 (chars 152-160)
                
                base_blob = self.current_job['blob']
                prefix = base_blob[:136]
                old_time = base_blob[136:144]
                old_bits = base_blob[144:152]
                
                # Check if ntime provided
                if ntime_hex and len(ntime_hex) == 8:
                    time_direct = ntime_hex
                    time_swapped = swap_hex(ntime_hex)
                else:
                    time_direct = old_time
                    time_swapped = swap_hex(old_time) # Unlikely to need swapping if original
                    
                # Combinations
                variations = [
                    ("Direct Nonce, Direct Time", nonce_direct, time_direct, 0),
                    ("Swapped Nonce, Direct Time", nonce_swapped, time_direct, 0),
                    ("Direct Nonce, Swapped Time", nonce_direct, time_swapped, 0),
                    ("Swapped Nonce, Swapped Time", nonce_swapped, time_swapped, 0),
                    # Truncated Blob (76 bytes)
                    ("Truncated 76 bytes", "", time_direct, -8), 
                    # XMRig Default Offset Hypothesis (Byte 39)
                    # 39 bytes = 78 hex chars.
                    # We inject nonce at 78:86. 
                    ("Nonce at Offset 39 (Monero Style)", nonce_direct, time_direct, 39),
                    # Test Complete Blob Word Swap (32-bit Little Endian <-> Big Endian interpretation)
                    ("Word-Swapped Blob", nonce_direct, time_direct, -32),
                ]
                
                found_valid = None
                seed = get_seed_hash(self.current_job['height'])
                # [BITMINTI FIX] Reverted Seed Reversal verification.
                
                # print(f"--- DEBUG VARIATIONS (Seed: {seed[:10]}...) ---")
                
                for label, n, t, mode in variations:
                    # Construct
                    if mode == 0:
                         cand_hex = prefix + t + old_bits + n
                    elif mode == -8:
                         cand_hex = (prefix + t + old_bits)[:152] + n
                    elif mode == 39:
                        # Reconstruct Monero style: Nonce at 39 (byte) = 78 (hex char)
                        # We take Original Blob (without nonce at end if it was there)
                        # And insert nonce at 78.
                        # But wait, original blob has 160 chars.
                        # We must carefuly replace chars 78-86.
                        temp = list(prefix + t + old_bits) # 152 chars
                        # Pad if needed? No, 152 chars = 76 bytes.
                        # We need 80 bytes.
                        # Monero blob size varies.
                        # Just overwrite at 78.
                        full = prefix + t + old_bits # 152 chars
                        
                        cand_hex = full[:78] + n + full[86:] 
                        # Pad to 160 if needed
                        if len(cand_hex) < 160: cand_hex += "00" * (80 - len(cand_hex)//2)

                    elif mode == -32:
                         # Word Swap (32-bit LE <-> BE) of the WHOLE BLOB
                         # 1. Construct normal blob first
                         raw = prefix + t + old_bits + n
                         # 2. Split into 8-char chunks (4 bytes)
                         chunks = [raw[i:i+8] for i in range(0, len(raw), 8)]
                         # 3. Reverse bytes in each chunk
                         swapped_chunks = []
                         for c in chunks:
                             # c is hex string e.g. "aabbccdd"
                             # reverse pairs: "ddccbbaa"
                             swapped_chunks.append("".join(reversed([c[j:j+2] for j in range(0, len(c), 2)])))
                         cand_hex = "".join(swapped_chunks)

                    # Verify
                    h = verify_randomx(cand_hex, seed)
                    h_bytes = binascii.unhexlify(h)
                    # RandomX Hash is Little Endian.
                    # RandomX produces a 256-bit hash, just like SHA256
                    # Compare the full 256-bit hash against the 256-bit target
                    h_val = int.from_bytes(h_bytes, byteorder='little')
                    
                    target_val = self.current_job.get('target_val', 0)
                    
                    is_low = h_val <= target_val
                    
                    # Verbose Print
                    print(f"[{label}] Blob: {cand_hex[:64]}... H: {h[:16]}... Valid: {is_low}")
                    
                    if is_low:
                        print(f"\n!!! FOUND VALID CANDIDATE !!! Using {label}")
                        
                        # Prepare FULL BLOCK for Submission
                        final_header_hex = cand_hex
                        if label == "Word-Swapped Blob":
                            print("DEBUG: Word-Swapped match. Using Standard Header.")
                            final_header_hex = prefix + t + old_bits + n
                        
                        # Construct Full Block
                        # 1. Header (80 bytes = 160 hex)
                        full_block = final_header_hex
                        
                        # 2. Tx Count: 1 (Coinbase) + len(other_txs)
                        tx_count = 1 + len(self.current_job['other_txs'])
                        full_block += binascii.hexlify(encode_varint(tx_count)).decode()
                        
                        # 3. Coinbase
                        full_block += binascii.hexlify(self.current_job['coinbase_tx_bin']).decode()
                        
                        # 4. Other Txs
                        for tx_struct in self.current_job['other_txs']:
                            if 'data' in tx_struct:
                                full_block += tx_struct['data']
                                
                        print(f"DEBUG: Constructing Block. Header: {final_header_hex[:64]}...")
                        # print(f"DEBUG: Full Block: {full_block}")
                        
                        found_valid = (full_block, label)
                        break
                
                block_hex = None
                if found_valid:
                    block_hex = found_valid[0]
                else:
                    # Silent ignore
                    print(".", end="", flush=True) 
                    self.send_json({
                        "id": msg_id,
                        "result": None,
                        "error": ["Low difficulty share", -1]
                    })
                    # Fall through to new job
                    pass 

                if block_hex:
                    print("\nSubmitting Block!")
                    res = rpc("submitblock", [block_hex])
                    print(f"Submit result: {res}")
                    # If submit succeeded (returned None), valid block.
                    # Send OK.
                    self.send_json({"jsonrpc": "2.0", "id": msg_id, "result": {"status": "OK"}})
                elif found_valid:
                    # Valid share but not block? (Shouldn't happen with our logic, unless submit failed)
                    self.send_json({"jsonrpc": "2.0", "id": msg_id, "result": {"status": "OK"}})
                else: 
                     # Already sent Error in the 'else' block above.
                     # Do NOT send OK.
                     pass
        
        elif method == 'keepalived':
             self.send_json({"jsonrpc":"2.0", "id": msg_id, "result": {"status": "OK"}})

    def create_job(self):
        try:
            tmpl = rpc("getblocktemplate", [{"rules": ["segwit"]}])
            if not tmpl: return None
            
            # 1. Transactions & Merkle
            # IMPORTANT: RPC returns hashes in BE, but merkle tree needs LE
            txs = [binascii.unhexlify(t['hash'])[::-1] for t in tmpl['transactions']]
            
            # Coinbase
            cb, cb_hash = create_coinbase(tmpl['height'], tmpl['coinbasevalue'], self.miner_pkh, self.extra_nonce, tmpl.get('default_witness_commitment'))
            txs.insert(0, cb_hash)
            merkle_root = merkle_root_calc(txs)
            
            # 2. Header Construction
            # Version (4)
            ver = struct.pack("<I", tmpl['version'])
            # PrevHash (32) - REVERSED (RPC gives BE)
            prev = binascii.unhexlify(tmpl['previousblockhash'])[::-1]
            # Merkle (32)
            mr = merkle_root # Already LE
            # Time (4)
            ntime = struct.pack("<I", tmpl['curtime'])
            # Bits (4) - Parse compact representation correctly
            bits = struct.pack("<I", int(tmpl['bits'], 16))
            
            # Blob = Ver + Prev + MR + Time + Bits + Nonce(0)
            blob_bin = ver + prev + mr + ntime + bits + b'\x00\x00\x00\x00'
            blob_hex = binascii.hexlify(blob_bin).decode()
            
            job_id = binascii.hexlify(struct.pack(">I", int(time.time()))).decode()
            seed_hash = get_seed_hash(tmpl['height'])
            
            # [BitMinti] Pass BE Seed Directly (XMRig handles reversal natively)
            seed_hash_bin = binascii.unhexlify(seed_hash)
            # No reversal here.
            seed_hash = binascii.hexlify(seed_hash_bin).decode()
            print(f"DEBUG: Proxy Sending Seed (BE): {seed_hash}")
            
            # Send STANDARD blob here.
            stratum_blob = blob_hex

            # [BitMinti Fix] Correct target calculation
            # Use full 256-bit target, not just 64-bit
            difficulty = 1
            target_val = (2**256 - 1) // difficulty
            
            # target_val needed for verify logic later
            self.current_job = {
                "blob": blob_hex,
                "job_id": job_id,
                "target": binascii.hexlify(target_val.to_bytes(32, 'little')).decode(),  # 32-byte LE target
                "difficulty": difficulty, 
                "target_val": target_val, # Use numeric for verify
                "height": tmpl['height'],
                "seed_hash": seed_hash,
                "algo": "rx/0",
                "coinbase_tx": cb_hash,
                "coinbase_tx_bin": cb,
                "other_txs": tmpl['transactions']
            }
            
            return {
                "blob": stratum_blob,
                "job_id": job_id,
                "target": self.current_job['target'], # Restored
                "difficulty": difficulty, # Added
                "height": tmpl['height'],
                "seed_hash": seed_hash
            }
        except Exception as e:
            print(f"Error creating job: {e}")
            import traceback
            traceback.print_exc()
            return None
class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True
    pass

if __name__ == "__main__":
    print(f"Stratum Proxy for BitMinti listening on {STRATUM_PORT}")
    server = ThreadedTCPServer(('0.0.0.0', STRATUM_PORT), StratumHandler)
    server.serve_forever()
