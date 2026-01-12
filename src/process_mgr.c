/*
 * Description:
 * Program A: Managing Workers using Process Model (fork).
 * This acts as the Orchestrator. It parses arguments, spawns children,
 * and waits for them to finish (avoiding Zombie processes).
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>     // for fork(), getpid()
#include <sys/wait.h>   // for waitpid()
#include <time.h>
#include "../include/workers.h"

// Helper function to print usage instructions
void print_usage(const char* prog_name) {
    fprintf(stderr, "Usage: %s <type> <count>\n", prog_name);
    fprintf(stderr, "  <type> : cpu | mem | io\n");
    fprintf(stderr, "  <count>: Number of processes (1-20)\n");
}

int main(int argc, char *argv[]) {
    // 1. Argument Validation
    if (argc != 3) {
        print_usage(argv[0]);
        return EXIT_FAILURE;
    }

    // 2. Parse Worker Type
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

    // 3. Parse Count
    int num_processes = atoi(argv[2]);
    if (num_processes < 1 || num_processes > 100) {
        fprintf(stderr, "[ERROR] Count must be between 1 and 100.\n");
        return EXIT_FAILURE;
    }

    printf("[Parent] PID %d starting %d processes of type '%s'...\n", 
           getpid(), num_processes, argv[1]);


    // 4. FORK LOOP (The Spawning Phase)
    // We create 'num_processes' children.
    // Each child will execute the worker function and then exit.
    
    // Store child PIDs so we can track them if needed (optional for PA01 but good practice)
    pid_t *child_pids = malloc(num_processes * sizeof(pid_t));
    if (!child_pids) {
        perror("[Manager] Malloc failed for PIDs");
        return EXIT_FAILURE;
    }

    struct timespec start_time, end_time;
    clock_gettime(CLOCK_MONOTONIC, &start_time); // Start Global Timer

    for (int i = 0; i < num_processes; i++) {
        pid_t pid = fork();

        if (pid < 0) {
            // Error Case: OS refused to create a process (e.g., limit reached)
            perror("[Manager] Fork failed");
            free(child_pids);
            return EXIT_FAILURE;
        }
        else if (pid == 0) {
            // CHILD PROCESS LOGIC
            // This code runs ONLY inside the child.
            // The child gets a copy of all variables, but has its own memory space.
            
            // 1. Configure the worker
            worker_config_t config;
            config.id = i;
            config.iterations = LOOP_COUNT; // Defined in workers.h (8000)
            config.type = type;

            // 2. Execute the work
            // Note: We call the wrapper directly. In process mode, we don't need
            // thread_worker_wrapper, but calling the specific function is cleaner.
            switch (type) {
                case WORKER_CPU: run_cpu_intensive(config.iterations); break;
                case WORKER_MEM: run_mem_intensive(config.iterations); break;
                case WORKER_IO:  run_io_intensive(config.iterations); break;
            }

            // 3. Exit explicitly
            // If we don't exit, the child will continue running the parent's code below!
            // We return the worker ID as the status code (just for tracking).
            exit(0); 
        }
        else {
            // PARENT PROCESS LOGIC
            // The parent receives the Child's PID.
            // We just record it and loop again to spawn the next one.
            child_pids[i] = pid;
            // printf("[Manager] Spawned Child %d (PID: %d)\n", i, pid); // Debug logging
        }
    }

    // 5. WAIT LOOP (The Synchronization Phase)
    // The parent MUST wait for all children.
    // If the parent exits early, children become "Orphans" (adopted by init).
    // If children exit and parent doesn't wait, they become "Zombies".

    int active_children = num_processes;
    while (active_children > 0) {
        int status;
        // wait(NULL) blocks until ANY child finishes.
        pid_t finished_pid = wait(&status);
        
        if (finished_pid > 0) {
            active_children--;
        } else {
            // Should not happen unless interrupted
            perror("[Manager] Wait error");
            break;
        }
    }

    clock_gettime(CLOCK_MONOTONIC, &end_time); // End Global Timer
    free(child_pids);

    // 6. REPORTING

    double elapsed = (end_time.tv_sec - start_time.tv_sec) + 
                     (end_time.tv_nsec - start_time.tv_nsec) / 1e9;

    printf("[Manager] All %d processes finished. Total time: %.4f seconds.\n", 
           num_processes, elapsed);

    return EXIT_SUCCESS;
}

