#include <string.h>
#include <cstdio>
#include <stdlib.h>
#include <iostream>
#include <time.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "sha256.h"

using namespace std;

#if defined(NDEBUG)
#define CUDA_CHECK(x)	(x)
#else
#define CUDA_CHECK(x)	do {\
		(x); \
		cudaError_t e = cudaGetLastError(); \
		if (cudaSuccess != e) { \
			printf("cuda failure \"%s\" at %s:%d\n", \
			       cudaGetErrorString(e), \
			       __FILE__, __LINE__); \
			exit(1); \
		} \
	} while (0)
#endif


const int targetBit = 6;
const int operationPerThread = 900; // you have to adjust it whenever execute for purpose(hash difficulty) what you want

__device__  int my_strlen(char *string) {
	int cnt = 0;
	while (string[cnt] != '\0') {
		++cnt;
	}
	return cnt;
}


__device__ int _atoi(char const *c) {

	int value = 0;
	int positive = 1;

	if (*c == '\0')
		return 0;

	if (*c == '-')
		positive = -1;

	while (*c) {
		if (*c > '0' && *c < '9')
			value = value * 10 + *c - '0';
		c++;
	}

	return value*positive;
}

__device__  void reverseString(char* s) {
	int size = my_strlen(s);
	char temp;

	for (int i = 0; i < size / 2; i++) {
		temp = s[i];
		s[i] = s[(size - 1) - i];
		s[(size - 1) - i] = temp;
	}
}

__device__ char* _itoa(long long val, char * buf, int radix) {

	char* p = buf;

	while (val) {

		if (radix <= 10)
			*p++ = (val % radix) + '0';

		else {
			int t = val % radix;
			if (t <= 9)
				*p++ = t + '0';
			else
				*p++ = t - 10 + 'a';
		}

		val /= radix;
	}

	*p = '\0';
	reverseString(buf);
	//reverse(buf); 
	return buf;
}

__device__  void my_strcpy(char *dest, const char *src) {
	int i = 0;
	do {
		dest[i] = src[i];
	} while (src[++i] != '\0');
}

__device__  void my_strcat(char *c, char *m) {
	while (*c != '\0') { c++; }
	while (*m != '\0') { *c++ = *m++; }
	*c = '\0';
}


__host__ void genRandomTransactionHash(char *dest, int length) {
	srand(time(NULL));

	char charset[] = "0123456789"
		"abcdefghijklmnopqrstuvwxyz"
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ";

	while (length-- > 1) {
		int index = (double)rand() / RAND_MAX * (sizeof charset - 1);
		*dest++ = charset[index];
	}
	*dest = '\0';
}

__device__  void prepareData(char* timestamp, char* transactionHash, char* nonce, char* output) {
	char input[200] = { 0, };
	char out[100];
	// sprintf(output, "%lu%s%s", timestamp, transactionHash, nonce);
	
	my_strcat(input, timestamp);
	my_strcat(input, transactionHash);
	my_strcat(input, nonce);
	sha256(input, my_strlen(input), output);
	
}

__device__ int count(char *c)
{
	int i, count;
	count = 0;
	for (i = 0; c[i] != NULL; i++)
	{
		if (c[i] == '0')
			count++;
		else
			break;
	}
	return count;
}

__device__ long long getNonce(int bx, int tx) {
	int txn, bxn;
	long long n;

	n = 0;
	bxn = operationPerThread;

	if (bx) {
		bxn = bxn * blockDim.x; // blockDim.x
		bxn *= bx;
	}

	txn = operationPerThread * tx;
	n += bxn;
	n += txn;

	return n;
}

__global__ void mine(char* timestamp, char* transaction, char* ret_nonce, char* ret_hash) {
	unsigned char isSuccess;
	char output[100];
	char nonce_str[100];
	long long numOfTrial = 0;
	long long nonce;

	nonce = getNonce((int)blockIdx.x, (int)threadIdx.x);

	for (int k = 0; k < operationPerThread; k++) {
		_itoa(nonce, nonce_str, 10);	
		prepareData(timestamp, transaction, nonce_str, output);	
		if (count(output) >= targetBit) {
			_itoa(numOfTrial, nonce_str, 10);
			my_strcpy(ret_nonce, nonce_str);
			my_strcpy(ret_hash, output);
			return;
		}	
		
		nonce--;
		numOfTrial++;
	}
}


__global__ void foo(char* ret_nonce) {
	char* input = "asdasd";
	char output[100];
	for (int i = 0; i < operationPerThread; i++) {
		prepareData("123123123", "123123123123", "123123123", output);
	}
}


__host__ char* myitoa(long long val, char * buf, int radix) {

	char* p = buf;

	while (val) {

		if (radix <= 10)
			*p++ = (val % radix) + '0';

		else {
			int t = val % radix;
			if (t <= 9)
				*p++ = t + '0';
			else
				*p++ = t - 10 + 'a';
		}

		val /= radix;
	}

	*p = '\0';

	//reverse(buf); 
	return buf;
}
__host__  void strcc(char *c, char *m) {
	while (*c != '\0') { c++; }
	while (*m != '\0') { *c++ = *m++; }
	*c = '\0';
}

__host__  int mystrlen(char *string) {
	int cnt = 0;
	while (string[cnt] != '\0') {
		++cnt;
	}
	return cnt;
}

int main(int argc, char* argv[]) {
	const int numOfBlocks = 10;  // you have to adjust it whenever execute for purpose(hash difficulty) what you want
	const int numOfThreads = 1024;
	char transaction[50];
	char* d_nonce;
	char* h_nonce;
	char* d_hash;
	char* h_hash;
	char* d_transaction;
	char* d_timestamp;
	dim3 blocks(numOfBlocks, 1, 1);
	dim3 threads(numOfThreads, 1, 1);
	unsigned long t = (unsigned long)time(NULL);
	char timestamp[20];
	cudaEvent_t start, stop;
	float ms = 0;
	CUDA_CHECK(cudaEventCreate(&start));
	CUDA_CHECK(cudaEventCreate(&stop));

	sprintf(timestamp, "%lu", t);
	genRandomTransactionHash(transaction, sizeof(transaction));

	h_nonce = (char*)malloc(sizeof(char) * 100);
	h_hash = (char*)malloc(sizeof(char) * 100);
	memset(h_nonce, 0, sizeof(char) * 100);
	memset(h_hash, 0, sizeof(char) * 100);
	CUDA_CHECK(cudaEventRecord(start));
	CUDA_CHECK(cudaMalloc((void**)&d_nonce, sizeof(char) * 100));
	CUDA_CHECK(cudaMalloc((void**)&d_hash, sizeof(char) * 100));
	CUDA_CHECK(cudaMalloc((void**)&d_transaction, sizeof(transaction)));
	CUDA_CHECK(cudaMalloc((void**)&d_timestamp, sizeof(timestamp)));
	CUDA_CHECK(cudaMemcpy(d_nonce, h_nonce, sizeof(char) * 100, cudaMemcpyHostToDevice));
	CUDA_CHECK(cudaMemcpy(d_hash, h_hash, sizeof(char) * 100, cudaMemcpyHostToDevice));
	CUDA_CHECK(cudaMemcpy(d_transaction, transaction, sizeof(transaction), cudaMemcpyHostToDevice));
	CUDA_CHECK(cudaMemcpy(d_timestamp, timestamp, sizeof(timestamp), cudaMemcpyHostToDevice));
	
	
	mine<<<blocks, threads >>> (d_timestamp, d_transaction, d_nonce, d_hash);
	CUDA_CHECK(cudaPeekAtLastError());
	CUDA_CHECK(cudaMemcpy(h_nonce, d_nonce, sizeof(char) * 100, cudaMemcpyDeviceToHost));
	CUDA_CHECK(cudaMemcpy(h_hash, d_hash, sizeof(char) * 100, cudaMemcpyDeviceToHost));
	printf("hash : %s\n", h_hash);
	CUDA_CHECK(cudaEventRecord(stop));
	cudaEventSynchronize(stop);
	CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));
	printf("The time duration : %fms\n", ms);

}


