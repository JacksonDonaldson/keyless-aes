import subprocess
import random
from Crypto.Cipher import AES
from pathlib import Path

def run_test(ciphertext, plaintext, thread_count, block_size, true_key):
    """Run keyless_aes.exe and return throughput"""
    ciphertext_hex = ciphertext.hex()
    plaintext_hex = plaintext.hex()
    cmd = ['./keyless_aes_wordlist.exe', ciphertext_hex, plaintext_hex, str(thread_count), str(block_size)]
    print(cmd)
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True
    )
    
    throughput = None
    for line in result.stdout.split('\n'):
        if 'The key is: ' in line:
            key = bytes.fromhex(line.split('The key is: ')[1])
            assert key == true_key, f"{key=}, {true_key=}"
        if 'keys/second' in line:
            throughput = float(line.split('(')[1].split()[0])
            print(f"results in {throughput} keys/second")
    
    if throughput is None:
        print("failed to get result! Output is:")
        print(result)
    return throughput

def main():
    key = b"correcthorsebatt"
    key = b"correct" + b"\x00" * (16 - len("correct"))
    cipher = AES.new(key, AES.MODE_ECB)
    
    plaintext = b'Test plaintext.\x00'
    ciphertext = cipher.encrypt(plaintext)


    # Test different thread counts and block sizes
    thread_counts = [2 ** i for i in range(16, 28, 2)]
    block_sizes = [32, 64, 128, 240, 256, 512]
    results = []

    for threads in thread_counts:
        for block_size in block_sizes:
            throughput = run_test(ciphertext, plaintext, threads, block_size, key)
            
            if throughput:
                results.append((threads, block_size, throughput))
            

    # Sort by throughput
    results.sort(key=lambda x: x[2], reverse=True)

    print("Thread Count | Block Size | Throughput (keys/sec)")
    print("-" * 50)
    for threads, block_size, throughput in results:
        print(f"{threads:12} | {block_size:10} | {throughput:.2e}")

if __name__ == "__main__":
    main()