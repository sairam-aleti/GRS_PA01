/*
 * Roll Number: MT25038
 */

#ifndef WORKERS_H
#define WORKERS_H

#include <stddef.h> 

// Configuration: Roll No MT25038 (Last Digit: 8)
#define ROLL_DIGIT 8
// Scaled loop count for consistent load
#define LOOP_COUNT (ROLL_DIGIT * 1000) 

typedef enum {
    WORKER_CPU,
    WORKER_MEM,
    WORKER_IO
} worker_type_t;

typedef struct {
    int id;
    size_t iterations;
    worker_type_t type;
} worker_config_t;

void run_cpu_intensive(size_t limit);
void run_mem_intensive(size_t limit);
void run_io_intensive(size_t limit);
void* thread_worker_wrapper(void* arg);

#endif