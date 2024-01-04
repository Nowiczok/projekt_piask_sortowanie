#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <stdint.h>
#include "utils.h"
#include "my_timers.h"
#include <mpi.h>

int arr[ARRAY_SIZE];
int arr_ref[ARRAY_SIZE];

int sendcounts[] = {ARRAY_SIZE/2, ARRAY_SIZE/2, 0, 0};
int displs[] = {0, ARRAY_SIZE/2, 0, 0};

int main(int argc, char** argv){
    int myrank;
    int size;
    int root=0;
    int* sub_buff;
    int64_t start, stop;
    double diff;
    sub_buff = malloc(ARRAY_SIZE/(PROC_NUM/2)*sizeof(MPI_INT));

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if(myrank == root){
        printf("populating arrays\n");
        populate_arrays(arr, arr_ref);
        start_time();
    }

    // distribute data across all 4 nodes
    MPI_Scatter(arr, ARRAY_SIZE/PROC_NUM, MPI_INT,
                sub_buff, ARRAY_SIZE/PROC_NUM, MPI_INT,
                root, MPI_COMM_WORLD);

    qsort(sub_buff, ARRAY_SIZE/PROC_NUM, sizeof(arr_ref[0]), cmpfunc);

    // retrieve sorted subarrays
    MPI_Gather(sub_buff,  ARRAY_SIZE/PROC_NUM, MPI_INT,      /* everyone sends 2 ints from local */
               arr, ARRAY_SIZE/PROC_NUM, MPI_INT,      /* root receives 2 ints each proc into arr */
               root, MPI_COMM_WORLD);   /* recv'ing process is root, all procs in */

    // distribute subarrays across 2 nodes
    MPI_Scatterv(arr, sendcounts, displs, MPI_INT,
                sub_buff, ARRAY_SIZE/2, MPI_INT,
                root, MPI_COMM_WORLD);

    merge(sub_buff, 0, ARRAY_SIZE/PROC_NUM-1, ARRAY_SIZE/(PROC_NUM/2)-1);

    // retrieve sorted subarrays
    MPI_Gatherv(sub_buff,  ARRAY_SIZE/2, MPI_INT,      /* everyone sends 2 ints from local */
               arr, sendcounts, displs, MPI_INT,      /* root receives 2 ints each proc into arr */
               root, MPI_COMM_WORLD);   /* recv'ing process is root, all procs in */

    free(sub_buff);
    if(myrank == root){
        // last merge
        merge(arr, 0, ARRAY_SIZE/2-1, ARRAY_SIZE-1);
        stop_time();
        print_time("Pararell sort completed. Elapsed:");

        start_time();
        qsort(arr_ref, ARRAY_SIZE, sizeof(arr_ref[0]), cmpfunc);
        stop_time();
        print_time("Reference sort completed. Elapsed:");

        if(memcmp(arr, arr_ref, sizeof(arr)) == 0){
            printf("\r\nsorting equivalent\r\n");
        }else{
            printf("\r\nsorting ERROR!\r\n");
        }
    }

    MPI_Finalize();
}
