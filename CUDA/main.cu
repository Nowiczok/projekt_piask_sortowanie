/**
* File: hello_gpu.cu
**/
/* Kernel – does nothing*/
#include <stdio.h>

// must be power of 2!
#define WORKERS 32 
#define ARRAY_LEN (1024*1024*1024)

__global__ void mykernel(void) {
}
int main(void) {
 mykernel<<<1,1>>>(); /* Launch mykernel on GPU */
 printf("Hello GPU!\n");
 return 0;
}