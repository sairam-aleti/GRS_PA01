/*
 * AI Declaration: 
 * The algorithms for 'Random Pointer Chasing' (Mem) and 'Prime Sieve' (CPU) 
 * were refined with AI assistance to specifically target hardware bottlenecks 
 * (L3 Cache Misses and ALU Latency) rather than generic usage.
 */

// _GNU_SOURCE required for O_DSYNC flag
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <string.h>
#include "../include/workers.h"


// 1. CPU WORKER: Integer Prime Sieve
// GOAL: Saturate the ALU (Arithmetic Logic Unit) without touching RAM.

void run_cpu_intensive(size_t limit) {
    size_t count = 0;
    size_t candidate = 10000; // Start at 10k to ensure non-trivial division

    // 'limit' here is the number of Primes we attempt to find.
    while (count < limit) {
        int is_prime = 1;
        
        // INNER LOOP: The "Hot" Path.
        // We use integer division (%) because it takes 20-50 CPU cycles
        // compared to addition (1 cycle). This maximizes CPU time per instruction.
        for (size_t i = 2; i * i <= candidate; i++) {
            if (candidate % i == 0) {
                is_prime = 0;
                break;
            }
        }
        
        // SYSTEM TRICK: Volatile Variable
        // If we don't use 'volatile', the compiler (-O3) will realize 
        // we never use the result and delete the entire loop (Dead Code Elimination).
        if (is_prime) {
             volatile size_t x = candidate;
             (void)x; // Cast to void to silence "unused variable" warnings
        }

        candidate++;
        count++;
    }
}


// 2. MEMORY WORKER: Random Pointer Chasing
// GOAL: Defeat the Hardware Prefetcher and force L3 Cache Misses.

void run_mem_intensive(size_t limit) {
    // 1. ALLOCATION
    // We allocate 64MB. Typical L3 Cache is 8-16MB.
    // This guarantees data must be fetched from main DRAM (slow).
    size_t num_elements = 16 * 1024 * 1024; 
    size_t array_size_bytes = num_elements * sizeof(int);
    
    int *arr = (int*)malloc(array_size_bytes);
    if (!arr) {
        perror("[ERROR] MemWorker malloc failed");
        exit(EXIT_FAILURE);
    }

    // 2. INITIALIZATION (Linear)
    for (size_t i = 0; i < num_elements; i++) {
        arr[i] = i;
    }

    // 3. SHUFFLE (The Setup)
    // We create a random linked list inside the array.
    // arr[0] -> holds index 500 -> arr[500] holds index 2...
    srand(time(NULL)); 
    for (size_t i = num_elements - 1; i > 0; i--) {
        size_t j = rand() % (i + 1);
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }

    // 4. THE CHASE (The Bottleneck)
    volatile int idx = 0;
    size_t count = 0;
    
    // SCALE FACTOR: 
    // CPU operations take ~0.5ns. Memory access takes ~100ns.
    // We increase the loop count to ensure this worker runs for a measurable duration.
    size_t adjusted_limit = limit * 10000; 

    while (count < adjusted_limit) {
        // DATA DEPENDENCY:
        // The CPU cannot calculate the next 'idx' until the current 'idx' 
        // is fetched from RAM. This forces a Pipeline Stall.
        idx = arr[idx]; 
        count++;
    }

    free(arr);
}


// 3. I/O WORKER: Synchronous Writer
// GOAL: Force the process into Uninterruptible Sleep (State 'D').

void run_io_intensive(size_t limit) {
    char filename[64];
    // SAFETY: Use getpid() so multiple processes don't write to the same file.
    snprintf(filename, sizeof(filename), "io_test_%d_%ld.tmp", getpid(), random());

    // O_DSYNC: Tells the kernel "Don't return until data is on the device".
    int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC | O_DSYNC, 0644);
    if (fd < 0) {
        perror("[ERROR] IOWorker open failed");
        exit(EXIT_FAILURE);
    }

    const char *payload = "MT25038_DATA";
    size_t count = 0;

    while (count < limit) {
        // Write small chunk
        if (write(fd, payload, 10) != 10) break;
        
        // SYSTEM CALL: fsync
        // Forces the disk controller to flush its buffer.
        // The CPU switches to another process while this thread sleeps.
        fsync(fd);
        count++;
    }

    close(fd);
    unlink(filename); // Cleanup temp file to save disk space
}

// 4. THREAD WRAPPER
// GOAL: Adapt strict worker signatures to pthread_create's void* interface.

void* thread_worker_wrapper(void* arg) {
    // Cast generic pointer back to our struct
    worker_config_t* config = (worker_config_t*)arg;
    
    switch(config->type) {
        case WORKER_CPU: run_cpu_intensive(config->iterations); break;
        case WORKER_MEM: run_mem_intensive(config->iterations); break;
        case WORKER_IO:  run_io_intensive(config->iterations); break;
    }
    
    return NULL;
}