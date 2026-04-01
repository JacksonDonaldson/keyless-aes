What:

This project attempts to recover an AES128 key given a ciphertext / plaintext pair by repeatedly guessing keys.

Exactly one key will cause the ciphertext to decrypt to the plaintext.
Finding that key is infeasible if it been generated in a cryptographically strong way (generally, randomly), as the entire 2 ^ 128 keyspace must be searched.
If instead you allow a user to choose a password and generate an AES key based on it, standard password-guessing techniques can be applied to reduce the keyspace searched.

The standard defensive technique used to prevent this attack is to run the user-entered password through a hashing algorithm a few hundred thousand times before using it as a key.
It's easy enough to imagine a tool which might skip that though.

How to run:

Requires nvcc.

run 'make'. This will build the gpu-accelerated aes decryptor 'keyless_aes.exe' and run a simple test using the example ciphertext and plaintext.
You can verify that the generated key matches the real one.

For a more complete test that runs across a number of thread counts and block sizes, run 
'make gpu_full_benchmark' 

This will produce a list of thread cound and block size combinations sorted by throughput. An example from running on an RTX 3060 is below.

Thread Count | Block Size | Throughput (keys/sec)
--------------------------------------------------
    67108864 |        128 | 7.14e+08
    67108864 |         64 | 7.09e+08
    67108864 |        256 | 7.01e+08
    67108864 |        512 | 6.79e+08
    67108864 |        240 | 6.64e+08
    16777216 |        128 | 6.63e+08
    16777216 |         64 | 6.55e+08
    67108864 |         32 | 6.49e+08
    16777216 |        256 | 6.49e+08
     4194304 |        128 | 6.44e+08
     4194304 |         64 | 6.35e+08
    16777216 |        512 | 6.24e+08
    16777216 |        240 | 6.17e+08
     1048576 |         64 | 6.07e+08
     4194304 |        256 | 6.05e+08
     4194304 |        512 | 6.03e+08
     1048576 |        256 | 5.98e+08
     4194304 |        240 | 5.96e+08
    16777216 |         32 | 5.88e+08
     1048576 |        128 | 5.85e+08
     1048576 |        512 | 5.74e+08
     4194304 |         32 | 5.71e+08
     1048576 |        240 | 5.69e+08
     1048576 |         32 | 5.50e+08
      262144 |        128 | 5.40e+08
      262144 |         64 | 5.35e+08
      262144 |        256 | 5.30e+08
      262144 |        240 | 5.05e+08
      262144 |         32 | 4.95e+08
      262144 |        512 | 4.92e+08
       65536 |         64 | 3.79e+08
       65536 |        128 | 3.78e+08
       65536 |        240 | 3.71e+08
       65536 |        256 | 3.69e+08
       65536 |        512 | 3.62e+08
       65536 |         32 | 3.60e+08
    67108864 |         16 | 3.43e+08
    16777216 |         16 | 3.14e+08
     4194304 |         16 | 3.10e+08
     1048576 |         16 | 3.01e+08
      262144 |         16 | 2.85e+08
       65536 |         16 | 2.39e+08
       16384 |        128 | 1.78e+08
       16384 |         64 | 1.75e+08
       16384 |        240 | 1.73e+08
       16384 |         32 | 1.71e+08
       16384 |        256 | 1.64e+08
       16384 |        512 | 1.56e+08
       16384 |         16 | 1.40e+08


For comparison, the repository also contains an openssl-based CPU implementation that can be built and ran on linux only with
'make cpu_benchmark'
On a Ryzen 7 5800X, this benchmark outputs:

Decryption successful. The key is: 2600ea00000000000000000000000000
Tried 15335462 keys in 5.96506 seconds (2.57088e+06 keys/second)

which is 1/350th of the throughput of the GPU implementation.

Notes:
Currently keys just count up. I intend to implement a more interesting search mechanism - perhaps a word list?

https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/AES_Core128.pdf
is an incredibly helpful resource for implementing AES, as it goes step-by-step through the decryption & encryption process

I used NSignt Compute to profile my code & get an idea of where I could find the most time - it's really quite good.

My 3060 makes a fun little whistling noise while running the benchmark. It's somewhat concerning, actually...