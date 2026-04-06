
#define AES_BLOCKSIZE 16
#define AES_KEYSIZE 16
#define AES_KEYSIZE_WORDS 4
#define AES_ROUNDS 10

typedef unsigned char byte;
typedef unsigned int uint;

#define SHMEM_PER_THREAD (AES_BLOCKSIZE)
#define SHMEM_OFFSET 256

__global__ void aes128_decrypt(const byte * ciphertext, uint64_t key_start, const byte * correct_plaintext, byte * correct_key);