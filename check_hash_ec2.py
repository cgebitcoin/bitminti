
import struct
import binascii
import subprocess
import os

# Parameters from Logs
# Seed: 6e49...
seed_hex = "6e4931d68287a8459a9fb066f07868495c36c7d12eb8bfe29285aaa11bf82b82"

# Blob (Standard) from Logs (Step 2940)
# "Constructed Blob: 00000020bdba..."
# We need the full blob.
# I'll paste the one from Step 2880 (which was Size 80) and assume it hasn't changed structure much (Version/Prev/Merkle same).
# Note: Merkle Root might change if Coinbase changes.
# But XMRig mined on *something*.
# Let's try to reconstruct from template parameters if possible, or just use a dummy blob with valid length for testing algo.
# Actually, strict reproducibility requires exact blob.
# But 'debug_rx' behavior change implies ALGO difference, which should manifest on ANY blob.
# So I will use the blob from Step 2836 (Initial Debug) but updated with Nonce 00800000.

blob_base = "00000020bdba3f548c054121cd85575ab24e66c5a615a56bb5dfe05c33bfaaf1f1d55d1ac033c3569f0a8763ec2128262784108cd267aa4f4c26216c0913fe9ec92103799a3c6369ffff0f1f"
# Length check: 152 chars = 76 bytes.
# Add Nonce: 00 80 00 00
nonce_hex = "00800000"
blob_full = blob_base + nonce_hex # 80 bytes

def swap32_hex(s):
    chunks = [s[i:i+8] for i in range(0, len(s), 8)]
    swapped = [ "".join(reversed([c[j:j+2] for j in range(0, len(c), 2)])) for c in chunks]
    return "".join(swapped)

blob_swapped = swap32_hex(blob_full)

print(f"Checking Hash for Seed: {seed_hex}")
print(f"Blob Swapped: {blob_swapped}")

# Run debug_rx
cmd = ["./debug_rx", seed_hex, blob_swapped]
try:
    result = subprocess.run(cmd, capture_output=True, text=True)
    print("Output:")
    print(result.stdout)
except Exception as e:
    print(f"Error: {e}")
