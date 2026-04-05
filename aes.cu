#include "aes.cuh"

__constant__ byte sbox[256] = {
  //0     1    2      3     4    5     6     7      8    9     A      B    C     D     E     F
  0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
  0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
  0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
  0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
  0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
  0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
  0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
  0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
  0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
  0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
  0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
  0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
  0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
  0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
  0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
  0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16 };

__constant__ byte rsbox[256] = {
  0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
  0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
  0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
  0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
  0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
  0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
  0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
  0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
  0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
  0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
  0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
  0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
  0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
  0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
  0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
  0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d };

#define ROTWORD(w) (((w >> 8) & 0xffffff) | (w << 0x18))

#define SUB(w, n) (sbox[*(((byte*)&w) + n)])

#define SUBWORD(w) ((SUB(w, 0)) | (SUB(w, 1) << 0x8) | (SUB(w, 2) << 0x10) | SUB(w, 3) << 0x18)




__device__ __forceinline__ void aes_key_expansion(const uint * key, uint * expanded_key){
    uint rcon = 0x01;
    //kick off the expanded key w/ the original key
    uint word1 = key[0];
    uint word2 = key[1];
    uint word3 = key[2];
    uint word4 = key[3]; 
    
    for(int i = 0; i < AES_ROUNDS; i++){
        //generate each word in the expanded key based on the previous few words + some shifts
        uint temp = word4;
        temp = ROTWORD(temp);
        temp = SUBWORD(temp) ^ rcon;

        rcon *= 2;
        //each thread should hit this if statements at the same time (doesn't depend on data)
        //so it shouldn't be a performance hit
        //(profiler agrees w/ me)
        if(rcon == 0x100){
            rcon = 0x1b;
        }

        word1 ^= temp;
        word2 ^= word1;
        word3 ^= word2;
        word4 ^= word3;

        expanded_key[i * 4] = word1;
        expanded_key[i * 4 + 1] = word2;
        expanded_key[i * 4 + 2] = word3;
        expanded_key[i * 4 + 3] = word4;
    }
}

__device__ __forceinline__ void add_round_key(byte * state, const byte * key){
    for(int i = 0; i < 4; i++){
        ((uint*)state)[i] ^= ((uint*)key)[i]; //lots of stalls here according to profiler - speedup maybe?
    }
}


__device__ __forceinline__ void inv_shift_rows(byte * state){
    uchar4 c0 = *((uchar4*)(state + 0));
    uchar4 c1 = *((uchar4*)(state + 4));
    uchar4 c2 = *((uchar4*)(state + 8));
    uchar4 c3 = *((uchar4*)(state + 12));

    uchar4 r0 = make_uchar4(c0.x, c3.y, c2.z, c1.w);
    uchar4 r1 = make_uchar4(c1.x, c0.y, c3.z, c2.w);
    uchar4 r2 = make_uchar4(c2.x, c1.y, c0.z, c3.w);
    uchar4 r3 = make_uchar4(c3.x, c2.y, c1.z, c0.w);

    *((uchar4*)(state + 0))  = r0;
    *((uchar4*)(state + 4))  = r1;
    *((uchar4*)(state + 8))  = r2;
    *((uchar4*)(state + 12)) = r3;

    //the above is just this; unclear if it really made a difference in runtime...
    // byte temp = state[13];
    // state[13] = state[9];
    // state[9] = state[5];
    // state[5] = state[1];
    // state[1] = temp;

    // temp = state[14];
    // state[14] = state[6];
    // state[6] = temp;
    // temp = state[10];
    // state[10] = state[2];
    // state[2] = temp;

    // temp = state[15];
    // state[15] = state[3];
    // state[3] = state[7];
    // state[7] = state[11];
    // state[11] = temp;
}


__device__ __forceinline__ void inv_sub_bytes(byte * state, byte * sharedrsbox){
    for(int i = 0; i < AES_BLOCKSIZE; i++){
        state[i] = sharedrsbox[state[i]];
    }
}

#define a_0 0xe
#define a_1 0x9
#define a_2 0xd
#define a_3 0xb

#define xtimes(n) ((((n >> 7) & 1) * 0x1b) ^ (n * 2))

// fast Galois field multiplies for AES coefficients 0x9,0xb,0xd,0xe
__device__ __forceinline__ byte galois_mult_9(byte b){
    return xtimes(xtimes(xtimes(b))) ^ b;
}

__device__ __forceinline__ byte galois_mult_b(byte b){
    return xtimes(xtimes(xtimes(b))) ^ xtimes(b) ^ b;
}

__device__ __forceinline__ byte galois_mult_d(byte b){
    return xtimes(xtimes(xtimes(b))) ^ xtimes(xtimes(b)) ^ b;
}

__device__ __forceinline__ byte galois_mult_e(byte b){
    return xtimes(xtimes(xtimes(b))) ^ xtimes(xtimes(b)) ^ xtimes(b);
}



__device__ __forceinline__ void inv_mix_columns(byte * state){

    for(int i = 0; i < AES_BLOCKSIZE / 4; i++){
        byte s_0 = state[i * 4 + 0];
        byte s_1 = state[i * 4 + 1];
        byte s_2 = state[i * 4 + 2];
        byte s_3 = state[i * 4 + 3];


        //for speed, define a separate function for galois multiplication by each possible number
        //rather than just 1 general one
        state[i * 4 + 0] = galois_mult_e(s_0) ^ galois_mult_b(s_1) ^ galois_mult_d(s_2) ^ galois_mult_9(s_3);
        state[i * 4 + 1] = galois_mult_9(s_0) ^ galois_mult_e(s_1) ^ galois_mult_b(s_2) ^ galois_mult_d(s_3);
        state[i * 4 + 2] = galois_mult_d(s_0) ^ galois_mult_9(s_1) ^ galois_mult_e(s_2) ^ galois_mult_b(s_3);
        state[i * 4 + 3] = galois_mult_b(s_0) ^ galois_mult_d(s_1) ^ galois_mult_9(s_2) ^ galois_mult_e(s_3);
    }
}


__device__ __forceinline__  void check_plaintext(const uint * plaintext, const uint * correct_plaintext, const byte * key, byte * right_key){
    for(unsigned int i = 0; i < AES_BLOCKSIZE / 4; i++){
        if(plaintext[i] != correct_plaintext[i]){
            return; //this isn't the right key
            //the speed improvement from an early return more than makes up for thread divergence here;
            //this'll almost always return after the first check (1 in 4 billion it doesn't)
        }
    }

    for(unsigned int i = 0; i < AES_KEYSIZE; i++){
        right_key[i] = key[i];
    }
    right_key[AES_KEYSIZE] = 1; //flag that we've found the key

}

#if defined(SIMPLE_KEY)
__device__ __forceinline__ void get_key(byte * key, int start) {
    int idx = (blockIdx.x * blockDim.x + threadIdx.x);
    int value = idx + start;
    for(int i = 0; i < 4; i++){
        key[i] = 0xff & (value >> (i * 8));
    }
    for(int i = 4; i < AES_KEYSIZE; i++){
        key[i] = 0;
    }
}
#else
#include "wordlist.cuh"
__device__ __forceinline__ void get_key(byte * key, int start) {
    int idx = (blockIdx.x * blockDim.x + threadIdx.x);
    int value = idx + start;
    const char* word1 = wordlist + (value / (WORDLIST_SIZE * WORDLIST_SIZE)) * WORD_SIZE;
    const char* word2 = wordlist + ((value / WORDLIST_SIZE) % WORDLIST_SIZE) * WORD_SIZE;
    const char* word3 = wordlist + (value % WORDLIST_SIZE) * WORD_SIZE;

    uint key_idx = 0;
    memcpy(key, word3 + 1, AES_KEYSIZE);
    key[15] = 0;
    // key_idx += *word1;
    // memcpy(key + key_idx, word2 + 1, min(AES_KEYSIZE - key_idx, *word2));
    // key_idx += *word2;
    // memcpy(key + key_idx, word3 + 1, min(AES_KEYSIZE - key_idx, *word3));
    // key_idx += *word3;

    // memset(key + key_idx, 0, AES_KEYSIZE - key_idx);

}
#endif

__global__ void aes128_decrypt(const byte * ciphertext, const uint key_start, const byte * correct_plaintext, byte * correct_key){



    extern __shared__ byte states[];
    //store the internal AES state in shmem
    byte * state = states + threadIdx.x * SHMEM_PER_THREAD + SHMEM_OFFSET;
    
    //first expand the key; each round of AES uses a different round key derived from the original.
    //To speed this up, I've tried:
    // storing this in shmem (requires too much memory, seems to slow down)

    // doing the key expansion dynamically 
    //     this doesn't work for decryption; we need the last round key first, but to get that we need to do the whole key expansion
    //     and we may as well just store the expanded key since we'll need the whole thing
    byte key[AES_KEYSIZE];
    byte expanded_key[AES_KEYSIZE * (AES_ROUNDS)];
    get_key(key, key_start);

    aes_key_expansion((uint*)key, (uint*)expanded_key);

    //copy the reverse sbox to shared memory; this is a massive speedup, since we're doing a bunch of random accesses to it.
    byte * sharedrsbox = states;
    for(int i = threadIdx.x; i < 256; i += blockDim.x){
        if(i < 256){
            sharedrsbox[i] = rsbox[i];
        }
    }
    __syncthreads();


    *(uint4*) state = *(uint4*) ciphertext;
    
    //this is just the definition of AES decryption;
    //see https://nvlpubs.nist.gov/nistpubs/fips/nist.fips.197.pdf
    add_round_key(state, expanded_key + (AES_ROUNDS-1) * AES_KEYSIZE);
    inv_sub_bytes(state, sharedrsbox);
    inv_shift_rows(state);

    //from AES_ROUNDS down, since we're decrypting
    for(int i = (AES_ROUNDS - 1); i >= 1; i--){
        add_round_key(state, expanded_key + AES_KEYSIZE * (i-1));
        
        inv_mix_columns(state);
        
        inv_sub_bytes(state, sharedrsbox);
        inv_shift_rows(state);
    }

    add_round_key(state, key);
    
    check_plaintext((uint *)state, (const uint *)correct_plaintext, key, correct_key);

}
