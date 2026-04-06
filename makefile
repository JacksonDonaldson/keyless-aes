default: gpu_single_benchmark

ifeq ($(OS),Windows_NT)

CXX := "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433\bin\Hostx64\x64\cl.exe"

else

CXX := g++

test/ciphertext: .FORCE
	openssl rand -out test/plaintext 16
	openssl rand -hex -out test/key 3
	truncate -s -1 test/key
	echo -n 00000000000000000000000000 >> test/key
	echo "generated key:" $$(cat test/key)


	openssl enc -aes-128-ecb -in test/plaintext -out test/ciphertext -nopad -nosalt -K $$(cat test/key)

keyless_aes_cpu_benchmark: keyless_aes_cpu_benchmark.cpp
	$(CXX) keyless_aes_cpu_benchmark.cpp -o keyless_aes_cpu_benchmark -lcrypto -Wno-deprecated-declarations

cpu_benchmark: keyless_aes_cpu_benchmark test/ciphertext
	./keyless_aes_cpu_benchmark $$(xxd -p test/ciphertext) $$(xxd -p test/plaintext)

endif

keyless_aes.exe: aes.cu keyless_aes.cu .FORCE
	nvcc aes.cu keyless_aes.cu -o $@ -ccbin $(CXX) -Xptxas=-v -DSIMPLE_KEY

keyless_aes_wordlist.exe: aes.cu keyless_aes.cu .FORCE
	nvcc aes.cu keyless_aes.cu -o $@ -ccbin $(CXX) -Xptxas=-v -DWORDLIST_KEY

gpu_single_benchmark: keyless_aes.exe
	./keyless_aes.exe $$(xxd -p test/ciphertext) $$(xxd -p test/plaintext) 67108864 128

gpu_full_benchmark: keyless_aes.exe
	py test/test_harness.py

wordlist.cuh:
	py generate_wordlist.py
	
gpu_wordlist_benchmark: keyless_aes_wordlist.exe wordlist.cuh
	./keyless_aes_wordlist.exe fdade589e73db3addf33a811edf80d8f 5465737420706c61696e746578742e00 67108864 128

clean:
	rm -rf keyless_aes_cpu_benchmark keyless_aes.exe keyless_aes_wordlist.exe wordlist.cuh

.FORCE: