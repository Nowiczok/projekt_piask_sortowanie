/* Iterative C program for merge sort */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <inttypes.h>
#include <omp.h>
#include<sys/time.h>
#include "my_timers.h"
 
/* Function to merge the two haves arr[l..m] and arr[m+1..r] of array arr[] */
void merge(int arr[], int l, int m, int r);
 
// Utility function to find minimum of two integers
int min_sort(int x, int y) { return (x<y)? x :y; }
 
 
/* Iterative mergesort function to sort arr[0...n-1] */
void mergeSort(int arr[], int n)
{
   int curr_size;  // For current size of subarrays to be merged
                   // curr_size varies from 1 to n/2
   int left_start; // For picking starting index of left subarray
                   // to be merged
 
   // Merge subarrays in bottom up manner.  First merge subarrays of
   // size 1 to create sorted subarrays of size 2, then merge subarrays
   // of size 2 to create sorted subarrays of size 4, and so on.
   for (curr_size=1; curr_size<=n-1; curr_size = 2*curr_size) {
       // Pick starting point of different subarrays of current size
       omp_set_num_threads(6);
       #pragma omp parallel for
       for (left_start=0; left_start<n-1; left_start += 2*curr_size) {
           // Find ending point of left subarray. mid+1 is starting 
           // point of right
           int mid = min_sort(left_start + curr_size - 1, n-1);
 
           int right_end = min_sort(left_start + 2*curr_size - 1, n-1);
 
           // Merge Subarrays arr[left_start...mid] & arr[mid+1...right_end]
           merge(arr, left_start, mid, right_end);
       }
   }
}
 
/* Function to merge the two haves arr[l..m] and arr[m+1..r] of array arr[] */
void merge(int arr[], int l, int m, int r)
{
    int i, j, k;
    int n1 = m - l + 1;
    int n2 =  r - m;
 
    /* create temp arrays */
    // int L[n1], R[n2];
    int* L = malloc(sizeof(int)*n1);
    int* R = malloc(sizeof(int)*n2);
 
    /* Copy data to temp arrays L[] and R[] */
    memcpy(L, &arr[l], n1*sizeof(arr[0]));
    memcpy(R, &arr[m + 1], n2*sizeof(arr[0]));

    /* Merge the temp arrays back into arr[l..r]*/
    i = 0;
    j = 0;
    k = l;
    while (i < n1 && j < n2){
        if (L[i] <= R[j]) {
            arr[k] = L[i];
            i++;
        } else {
            arr[k] = R[j];
            j++;
        }
        k++;
    }
 
    /* Copy the remaining elements of L[], if there are any */
    while (i < n1) {
        arr[k] = L[i];
        i++;
        k++;
    }
 
    /* Copy the remaining elements of R[], if there are any */
    while (j < n2) {
        arr[k] = R[j];
        j++;
        k++;
    }

    free(L);
    free(R);
}
 
/* Function to print an array */
void printArray(int A[], int size)
{
    int i;
    for (i=0; i < size; i++)
        printf("%d ", A[i]);
    printf("\n");
}

// float input_list[] = {6.7f, 3.8f, 9.2f, 12.5f, 10.6f, 1.3f, 4.9f, 5.5f};

int cmpfunc (const void * a, const void * b) {
   return ( *(int*)a - *(int*)b );
}

int64_t micros()
{
    struct timeval tv;
    gettimeofday(&tv,NULL);
    return tv.tv_sec * 1000000 + tv.tv_usec;
}

#define ARRAY_SIZE 10000000

/* Driver program to test above functions */
int main()
{
    // prepare test data
    srand(time(NULL));
    int arr[ARRAY_SIZE];
    int ref_arr[ARRAY_SIZE];
    for(int i = 0 ; i < ARRAY_SIZE; i++){
        arr[i] = rand() % 100;
    }
    int n = sizeof(arr)/sizeof(arr[0]);
    memcpy(ref_arr, arr, sizeof(arr));

    int64_t start,end;
    double dif;

    printf("\r\n BEGIN TEST \r\n");

    // printArray(arr, n);

    start_time();
    mergeSort(arr, n);
    stop_time();
    print_time("Pararell mergesort completed. Elapsed:");
    // printArray(arr, n);

    start_time();
    qsort(ref_arr, n, sizeof(ref_arr[0]), cmpfunc);
    stop_time();
    print_time("Reference qsort completed. Elapsed:");
    // printArray(ref_arr, n);

    if(memcmp(arr, ref_arr, sizeof(arr)) == 0){
        printf("\r\nsorting equivalent\r\n");
    }

    printf("\r\n END TEST \r\n");
    
    return 0;
}