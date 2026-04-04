#include <stdio.h>
#include <stdlib.h>
#include <chrono>
#include <assert.h>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <vector>
#include <cstring>
#include "aes.cuh"


#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}


std::vector<byte> hex_to_bytes(const std::string& hex) {
    std::vector<byte> bytes;
    for (size_t i = 0; i < hex.length(); i += 2) {
        unsigned int next_byte;
        std::istringstream(hex.substr(i, 2)) >> std::hex >> next_byte;
        bytes.push_back(static_cast<byte>(next_byte));
    }
    return bytes;
}

std::string bytes_to_hex(const byte* bytes, size_t length) {
    std::ostringstream oss;
    oss << std::hex << std::setfill('0');
    for (size_t i = 0; i < length; ++i) {
        oss << std::setw(2) << static_cast<int>(bytes[i]);
    }
    return oss.str();
}




void guess_keys(int numBlocks, int blockSize, byte * ciphertext, byte * expected_plaintext){
    unsigned long long count = numBlocks * blockSize;

    byte* keys, *plaintexts, *device_correct_key, *device_ciphertext, *device_correct_plaintext;
    byte* host_correct_key;

    cudaMalloc(&keys, count * AES_KEYSIZE);
    cudaMalloc(&plaintexts, count * AES_BLOCKSIZE);

    cudaMalloc(&device_ciphertext, AES_BLOCKSIZE);
    cudaMalloc(&device_correct_plaintext, AES_BLOCKSIZE);
    cudaMalloc(&device_correct_key, AES_KEYSIZE + 1);
    cudaMemset(device_correct_key, 0xff, AES_KEYSIZE + 1);

    
    cudaMemcpy(device_correct_plaintext, expected_plaintext, AES_BLOCKSIZE, cudaMemcpyHostToDevice);
    cudaMemcpy(device_ciphertext, ciphertext, AES_BLOCKSIZE, cudaMemcpyHostToDevice);
    
    host_correct_key = (byte*) malloc(AES_KEYSIZE + 1);
    memset(host_correct_key, 0xff, AES_KEYSIZE + 1);
    


    std::cout << "running..." << std::endl;
    auto start = std::chrono::high_resolution_clock::now();
    int i = 0;
    int guesses_per_iteration = numBlocks * blockSize;

    //when we find a plaintext that matches the expected plaintext, check_plaintexts will write the right key to host_correct_key (and this'll stop)
    while(host_correct_key[AES_KEYSIZE] != 1){

        //generate the next batch of keys to test
        // get_keys<<<numBlocks, blockSize>>>(keys, i * guesses_per_iteration);

        //run a decryption for each of those keys
        aes128_decrypt<<<numBlocks, blockSize, blockSize * AES_BLOCKSIZE + 256>>>(device_ciphertext, i * guesses_per_iteration, device_correct_plaintext, device_correct_key);

        // //check if the decrypted plaintexts match the expected plaintext, and if so write the correct key to host_correct_key
        // check_plaintexts<<<numBlocks, blockSize>>>(plaintexts, device_correct_plaintext, keys, device_correct_key);
        gpuErrchk( cudaMemcpy(host_correct_key, device_correct_key, AES_KEYSIZE+1, cudaMemcpyDeviceToHost) );
        i++;
    }
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    double seconds = duration.count();
    double keys_per_second = (i * (long long int)guesses_per_iteration) / seconds;
    std::cout << "Decryption successful. The key is: " << bytes_to_hex(host_correct_key, 16) << std::endl;
    std::cout << "Tried " << i * guesses_per_iteration << " keys in " << seconds << " seconds (" << keys_per_second << " keys/second)" << std::endl;

    cudaFree(keys);
    cudaFree(plaintexts);
    cudaFree(device_ciphertext);
    cudaFree(device_correct_plaintext);
    cudaFree(device_correct_key);
    free(host_correct_key);
}

int main(int argc, char** argv)
{
	// read command line arguments
	if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " <ciphertext_hex_32chars> <plaintext_hex_32chars> [totalThreads] [blockSize]" << std::endl;
        return 1;
    }

    std::string ciphertext_hex = argv[1];
    std::string plaintext_hex = argv[2];

    if (ciphertext_hex.length() != AES_BLOCKSIZE * 2 || plaintext_hex.length() != AES_BLOCKSIZE * 2) {
        std::cerr << "Error: Both blocks must be 32 hex characters (16 bytes)." << std::endl;
        return 1;
    }

    std::vector<byte> ciphertext = hex_to_bytes(ciphertext_hex);
    std::vector<byte> expected_plaintext = hex_to_bytes(plaintext_hex);

    int totalThreads = (1 << 20);
	int blockSize = 256;
	

	if (argc >= 4) {
		totalThreads = atoi(argv[3]);
	}
	if (argc >= 5) {
		blockSize = atoi(argv[4]);
	}

	int numBlocks = totalThreads/blockSize;

	// validate command line arguments
	if (totalThreads % blockSize != 0) {
		++numBlocks;
		totalThreads = numBlocks*blockSize;
		
        std::cout << "Warning: Total thread count is not evenly divisible by the block size\n";
        std::cout << "The total number of threads will be rounded up to " << totalThreads << "\n";
	}
    std::cout << "Running with: " << numBlocks << " blocks " << blockSize << " threads per block\n";
    guess_keys(numBlocks, blockSize, ciphertext.data(), expected_plaintext.data());
    std::cout << "\n\n";

	return 0;
}
