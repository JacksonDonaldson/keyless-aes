
#define AES_BLOCKSIZE 16
#define AES_KEYSIZE 16
#define AES_KEYSIZE_WORDS 4
#define AES_ROUNDS 10

typedef unsigned char byte;
typedef unsigned int uint;

__global__ void aes128_decrypt(const byte * ciphertext, const byte * keys, byte * plaintexts);