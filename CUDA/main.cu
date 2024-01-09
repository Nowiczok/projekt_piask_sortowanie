#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <thrust/device_vector.h>
#include <thrust/copy.h>
#include <thrust/sort.h>
#include <time.h>
#include <sys/time.h>
#include <vector>

#define ARRAY_SIZE 100000
#define BLOCK_SIZE 256

int cmpfunc(const void *a, const void *b) {
    return (*(int *)a - *(int *)b);
}


void thrustSortGPU(int *arr, int n) {
    thrust::device_vector<int> d_arr(arr, arr + n);

    thrust::sort(d_arr.begin(), d_arr.end());

    cudaMemcpy(arr, thrust::raw_pointer_cast(d_arr.data()), n * sizeof(int), cudaMemcpyDeviceToHost);
}


__global__ void mergeSortAndMerge1(int *arr, int n, int curr_size) {
    int tid = threadIdx.x + blockIdx.x * blockDim.x;

    int left_start = tid * 2 * curr_size;
    int mid = left_start + curr_size - 1;
    int right_end = min(left_start + 2 * curr_size - 1, n - 1);

    if (left_start < n - 1) {

        int i, j, k;
        int n1 = mid - left_start + 1;
        int n2 = right_end - mid;

        int *L = &arr[left_start];
        int *R = &arr[mid + 1];

        int *tempL = new int[n1];
        int *tempR = new int[n2];

        for (i = 0; i < n1; i++)
            tempL[i] = L[i];
        for (j = 0; j < n2; j++)
            tempR[j] = R[j];

        i = 0;
        j = 0;
        k = left_start;
        while (i < n1 && j < n2) {
            if (tempL[i] <= tempR[j]) {
                arr[k] = tempL[i];
                i++;
            } else {
                arr[k] = tempR[j];
                j++;
            }
            k++;
        }

        while (i < n1) {
            arr[k] = tempL[i];
            i++;
            k++;
        }

        while (j < n2) {
            arr[k] = tempR[j];
            j++;
            k++;
        }

        delete[] tempL;
        delete[] tempR;
    }
}


void mergeSortAndMergeGPU1(int *arr, int n) {
    int *d_arr;


    cudaMalloc((void**)&d_arr, n * sizeof(int));


    cudaMemcpy(d_arr, arr, n * sizeof(int), cudaMemcpyHostToDevice);

    int curr_size = 1;

    while (curr_size <= n - 1) {
        int num_blocks = (n - 1) / (2 * curr_size) + 1;
        mergeSortAndMerge1<<<num_blocks, 1>>>(d_arr, n, curr_size);
        cudaDeviceSynchronize(); 
        curr_size = 2 * curr_size;
    }

    cudaMemcpy(arr, d_arr, n * sizeof(int), cudaMemcpyDeviceToHost);

    cudaFree(d_arr);
}





__global__ void mergeSortAndMerge(int *arr, int *temp, int n, int curr_size) {
    int tid = threadIdx.x + blockIdx.x * blockDim.x;

    int left_start = tid * 2 * curr_size;
    int mid = left_start + curr_size - 1;
    int right_end = min(left_start + 2 * curr_size - 1, n - 1);

    if (left_start < n) { 

        int i = left_start;
        int j = mid + 1;
        int k = left_start; 

        while (i <= mid && j <= right_end) {
            if (arr[i] <= arr[j]) {
                temp[k] = arr[i];
                i++;
            } else {
                temp[k] = arr[j];
                j++;
            }
            k++;
        }

        while (i <= mid) {
            temp[k] = arr[i];
            i++;
            k++;
        }

        while (j <= right_end) {
            temp[k] = arr[j];
            j++;
            k++;
        }

        for (i = left_start; i <= right_end; i++) {
            arr[i] = temp[i];
        }
    }
}

void mergeSortAndMergeGPU(int *arr, int n) {
    thrust::device_vector<int> d_arr(arr, arr + n);
    thrust::device_vector<int> d_temp(n);

    int curr_size = 1;
    while (curr_size <= n - 1) {
        int num_blocks = (n - 1) / (2 * curr_size) + 1;
        mergeSortAndMerge<<<num_blocks, BLOCK_SIZE>>>(
            thrust::raw_pointer_cast(d_arr.data()),
            thrust::raw_pointer_cast(d_temp.data()),
            n,
            curr_size);
        cudaDeviceSynchronize(); 
        curr_size = 2 * curr_size;
    }

    thrust::copy(d_arr.begin(), d_arr.end(), arr);
}



int isSorted(int *arr, int size) {
    for (int i = 1; i < size; i++) {
        if (arr[i - 1] > arr[i]) {
            return 0; 
        }
    }
    return 1; 
}

int64_t micros() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec * 1000000 + tv.tv_usec;
}

int main() {
    int arr[ARRAY_SIZE];
    int ref_arr[ARRAY_SIZE];
    int ref_arr2[ARRAY_SIZE];
    int ref_arr3[ARRAY_SIZE];

    srand(time(NULL));
    for (int i = 0; i < ARRAY_SIZE; i++) {
        arr[i] = rand() % 100;
    }
    int n = sizeof(arr) / sizeof(arr[0]);

    memcpy(ref_arr, arr, sizeof(arr));
    memcpy(ref_arr2, arr, sizeof(arr));
    memcpy(ref_arr3, arr, sizeof(arr));
    int64_t start, end;
    double dif;

    printf("\r\nBEGIN TEST\r\n");

    start = micros();
    //mergeSortAndMergeGPU(arr, ARRAY_SIZE);
    thrustSortGPU(arr, ARRAY_SIZE);
    end = micros();
    dif = (double)(end - start) / 1000;
    printf("thrust::sort on GPU completed, %.3lf ms elapsed\n", dif);

    if (isSorted(arr, ARRAY_SIZE)) {
        if (ARRAY_SIZE != sizeof(arr) / sizeof(arr[0])) {
            printf("Array size GPU ERROR\n");
        }
        printf("Sorting on GPU is correct\n");
    } else {
        printf("Sorting on GPU is incorrect\n");
    }

    start = micros();
    qsort(ref_arr, n, sizeof(ref_arr[0]), cmpfunc);
    end = micros();
    dif = (double)(end - start) / 1000;
    printf("Reference qsort completed, %.3lf ms elapsed\n", dif);

    if (isSorted(ref_arr, ARRAY_SIZE)) {
        printf("Reference sorting is correct\n");
    } else {
        printf("Reference sorting is incorrect\n");
    }

    if (memcmp(arr, ref_arr, sizeof(arr)) == 0) {
        printf("\r\nSorting equivalent\r\n");
    } else {
        printf("\r\nSorting ERROR!!!!!!!!\r\n");
    }

    start = micros();
    mergeSortAndMergeGPU1(ref_arr3, ARRAY_SIZE);
    end = micros();
    dif = (double)(end - start) / 1000;
    printf("MergeSort no thrust lib on GPU completed, %.3lf ms elapsed\n", dif);

    if (isSorted(ref_arr3, ARRAY_SIZE)) {
        printf("Reference sorting is correct\n");
    } else {
        printf("Reference sorting is incorrect\n");
    }

    if (memcmp(arr, ref_arr3, sizeof(arr)) == 0) {
        printf("\r\nSorting equivalent\r\n");
    } else {
        printf("\r\nSorting ERROR!!!!!!!!\r\n");
    }




    start = micros();
    mergeSortAndMergeGPU(ref_arr2, ARRAY_SIZE);
    end = micros();
    dif = (double)(end - start) / 1000;
    printf("MergeSort on GPU completed, %.3lf ms elapsed\n", dif);

    if (isSorted(ref_arr2, ARRAY_SIZE)) {
        printf("Reference sorting is correct\n");
    } else {
        printf("Reference sorting is incorrect\n");
    }

    if (memcmp(arr, ref_arr2, sizeof(arr)) == 0) {
        printf("\r\nSorting equivalent\r\n");
    } else {
        printf("\r\nSorting ERROR!!!!!!!!\r\n");
    }


    printf("\r\nEND TEST\r\n");

    return 0;
}
