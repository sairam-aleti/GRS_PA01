/*
 * Description:
 * Program B: Managing Workers using Thread Model (pthreads).
 * This acts as the Orchestrator for threads.
 * KEY DIFFERENCE FROM PROCESS MGR:
 * Instead of fork() (which copies memory), we use pthread_create() 
 * (which shares memory). This requires passing arguments via pointers.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>    // The Pthread Library
#include <time.h>
#include <unistd.h>     // for getpid()
#include "../include/workers.h"

// Helper function to print usage instructions
void print_usage(const char* prog_name) {
    fprintf(stderr, "Usage: %s <type> <count>\n", prog_name);
    fprintf(stderr, "  <type> : cpu | mem | io\n");
    fprintf(stderr, "  <count>: Number of threads (1-20)\n");
}

int main(int argc, char *argv[]) {
    // 1. ARGUMENT PARSING (Identical to Process Manager)

    if (argc != 3) {
        print_usage(argv[0]);
        return EXIT_FAILURE;
    }

    worker_type_t type;
    if (strcmp(argv[1], "cpu") == 0) {
        type = WORKER_CPU;
    } else if (strcmp(argv[1], "mem") == 0) {
        type = WORKER_MEM;
    } else if (strcmp(argv[1], "io") == 0) {
        type = WORKER_IO;
    } else {
        fprintf(stderr, "[ERROR] Invalid worker type: %s\n", argv[1]);
        return EXIT_FAILURE;
    }

    int num_threads = atoi(argv[2]);
    if (num_threads < 1 || num_threads > 100) {
        fprintf(stderr, "[ERROR] Count must be between 1 and 100.\n");
        return EXIT_FAILURE;
    }

    printf("[Main] PID %d starting %d threads of type '%s'...\n", 
           getpid(), num_threads, argv[1]);

    // 2. RESOURCE ALLOCATION
    // Unlike fork(), we need to manually allocate memory for thread handles
    // and argument structs.
    
    pthread_t *threads = malloc(num_threads * sizeof(pthread_t));
    worker_config_t *configs = malloc(num_threads * sizeof(worker_config_t));

    if (!threads || !configs) {
        perror("[Manager] Malloc failed");
        return EXIT_FAILURE;
    }

    // 3. THREAD CREATION LOOP
    
    struct timespec start_time, end_time;
    clock_gettime(CLOCK_MONOTONIC, &start_time); // Start Timer

    for (int i = 0; i < num_threads; i++) {
        // PREPARE DATA:
        // We must fill the struct *before* creating the thread.
        // Each thread gets its own slot in the 'configs' array to avoid race conditions.
        configs[i].id = i;
        configs[i].iterations = LOOP_COUNT; // 8000
        configs[i].type = type;

        // SPAWN THREAD:
        // arg 1: Pointer to thread handle
        // arg 2: Attributes (NULL = default)
        // arg 3: The function to run (must return void* and take void*)
        // arg 4: The argument to pass (casted to void*)
        if (pthread_create(&threads[i], NULL, thread_worker_wrapper, &configs[i]) != 0) {
            perror("[Manager] pthread_create failed");
            // In a real system, we might cancel previous threads here.
            free(threads);
            free(configs);
            return EXIT_FAILURE;
        }
    }

    // -----------------------------------------------------------------------
    // 4. JOIN LOOP (The Synchronization)
    // -----------------------------------------------------------------------
    // This is equivalent to 'waitpid' in processes.
    // We strictly wait for thread 0, then thread 1, etc.
    // Even if thread 5 finishes first, we wait for 0. This is fine for benchmarking total time.
    
    for (int i = 0; i < num_threads; i++) {
        // pthread_join blocks the calling thread (Main) until the target thread terminates.
        if (pthread_join(threads[i], NULL) != 0) {
            perror("[Manager] pthread_join failed");
        }
    }

    clock_gettime(CLOCK_MONOTONIC, &end_time); // Stop Timer

    // 5. CLEANUP & REPORTING
    
    double elapsed = (end_time.tv_sec - start_time.tv_sec) + 
                     (end_time.tv_nsec - start_time.tv_nsec) / 1e9;

    printf("[Manager] All %d threads finished. Total time: %.4f seconds.\n", 
           num_threads, elapsed);

    // Free the heap memory we allocated
    free(threads);
    free(configs);

    return EXIT_SUCCESS;
}