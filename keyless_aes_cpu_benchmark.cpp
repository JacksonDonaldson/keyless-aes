#include <openssl/aes.h>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <vector>
#include <cstring>
#include <chrono>

std::vector<unsigned char> hex_to_bytes(const std::string& hex) {
    std::vector<unsigned char> bytes;
    for (size_t i = 0; i < hex.length(); i += 2) {
        unsigned int byte;
        std::istringstream(hex.substr(i, 2)) >> std::hex >> byte;
        bytes.push_back(static_cast<unsigned char>(byte));
    }
    return bytes;
}
std::string bytes_to_hex(const unsigned char* bytes, size_t length) {
    std::ostringstream oss;
    oss << std::hex << std::setfill('0');
    for (size_t i = 0; i < length; ++i) {
        oss << std::setw(2) << static_cast<int>(bytes[i]);
    }
    return oss.str();
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <ciphertext_hex_32chars> <plaintext_hex_32chars>" << std::endl;
        return 1;
    }

    std::string ciphertext_hex = argv[1];
    std::string plaintext_hex = argv[2];

    if (ciphertext_hex.length() != 32 || plaintext_hex.length() != 32) {
        std::cerr << "Error: Both blocks must be 32 hex characters (16 bytes)." << std::endl;
        return 1;
    }

    std::vector<unsigned char> ciphertext = hex_to_bytes(ciphertext_hex);
    std::vector<unsigned char> expected_plaintext = hex_to_bytes(plaintext_hex);

    unsigned char key[16] = {0};
    unsigned char decrypted[16];

    AES_KEY aes_key;


    auto start = std::chrono::high_resolution_clock::now();
    int i = 0;
    while(true){
        for (int j = 0; j < 16; ++j) {
            if (++key[j] != 0) break;
        }
        
        AES_set_decrypt_key(key, 128, &aes_key);
        AES_decrypt(ciphertext.data(), decrypted, &aes_key);
        i++;
        if (std::memcmp(decrypted, expected_plaintext.data(), 16) == 0){
            break;
        }
        

    }
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    double seconds = duration.count();
    double keys_per_second = i / seconds;

    std::cout << "Decryption successful. The key is: " << bytes_to_hex(key, 16) << std::endl;
    std::cout << "Tried " << i << " keys in " << seconds << " seconds (" << keys_per_second << " keys/second)" << std::endl;

    return 0;
}