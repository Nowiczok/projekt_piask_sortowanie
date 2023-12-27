#define ARRAY_SIZE 100000000
#define PROC_NUM 4

int cmpfunc (const void * a, const void * b);
int64_t micros();
void populate_arrays(int arr[], int arr_ref[]);
void printArray(int A[], int size);
void merge(int arr[], int l, int m, int r);