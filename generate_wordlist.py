with open('wordlist.txt', 'r') as f:
    words = [word.strip() for word in f.readlines()]

# Generate CUDA header file
output = """
#define WORDLIST_SIZE 5000
#define WORD_SIZE 16

__constant__ const char* wordlist = {
"""

# Add words as string literals
for i, word in enumerate(words):
    word = word[:15]
    wordlen = len(word)
    word = word.ljust(15, '0')
    word = word.replace('0', '\\x00')
    word = "\\x" + wordlen.to_bytes(1, byteorder='little').hex() +'" "' + word
        
    output += f'    "{word}"'
    if i < len(words) - 1:
        output += " \\"
    output += "\n"

output += "};"

# Write to file
with open('wordlist.cuh', 'w') as f:
    f.write(output)