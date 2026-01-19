Process vs. Thread Scalability Analysis

Course: Graduate Systems (CSE638) - PA01
Name: Sai Ram Reddy Aleti
Roll Number: MT25038
Date: January 2026

📖 Project Overview

This project implements and benchmarks two concurrency models—Multi-Processing (fork) and Multi-Threading (pthread)—to analyze their scalability across CPU, Memory, and I/O intensive tasks.

The system is designed to measure:

Scalability: How execution time changes as the worker count increases (1 to 64).

Resource Efficiency: CPU utilization and Memory footprint (RSS).

System Overhead: Context switching costs and disk I/O throughput.

📂 Directory Structure
GRS_PA01/
├── src/
│   ├── MT25038_Part_A_Program_A.c    # Process Manager (fork implementation)
│   ├── MT25038_Part_A_Program_B.c    # Thread Manager (pthread implementation)
│   └── MT25038_Part_A_Workers.c      # Worker payloads (CPU, Mem, I/O logic)
├── include/
│   └── MT25038_Part_A_Workers.h      # Shared headers and definitions
├── results/
│   ├── MT25038_Part_C_CSV.csv        # Process Model Metrics (Time, CPU, Mem, I/O)
│   └── MT25038_Part_D_CSV.csv        # Thread Model Metrics (Time, CPU, Mem, I/O)
├── plots/                            # Scalability Graphs (Generated via Python)
├── scripts/
│   ├── benchmark.sh                  # Automation script for data collection
│   └── plot_results.py               # Python script for graph generation
├── bin/                              # Compiled executables (created during build)
├── Makefile                          # Build automation
└── MT25038_Report.pdf                # Final Analysis Report

🛠️ Build Instructions

This project uses a standard Makefile for compilation.

Prerequisites: GCC, Make, Python3 (for plotting).

Bash

# Clean previous builds (keeps results/ intact)
make clean

# Compile the project
make


Artifacts bin/process_mgr and bin/thread_mgr will be created.

🚀 Usage & Benchmarking

Run the Automated Benchmark
To reproduce the data, run the shell script. It iterates through worker counts [1, 2, 4, 8, 16, 32, 64] for all three task types. (Note: This process takes ~10-15 minutes due to IO/Memory stress tests).

Bash

./scripts/benchmark.sh


Output: The script populates results/ with CSV files containing:

Execution Time (time -f %e)

CPU Utilization (time -f %P)

Peak Memory (time -f %M)

Disk IO Operations (time -f %O)

Generate Scalability Plots
Use the Python script to visualize the CSV data.

Bash

# Requires: pandas, matplotlib
python3 scripts/plot_results.py


Output: Scalability graphs (PNG) are saved to the plots/ directory.

🤖 AI Usage Declaration

Compliance Statement: I, MT25038, declare that Generative AI tools were used in the development of this assignment in accordance with the course policy. I have verified all generated code and fully understand the implementation logic.

Specific Usage:

Algorithm Optimization: The 'Prime Sieve' (CPU) and 'Pointer Chasing' (Mem) algorithms were refined with AI assistance to specifically target hardware bottlenecks (ALU latency vs. L3 Cache misses).

Debugging: AI assisted in diagnosing a "Lock Contention" bug in the rand() function, which initially caused poor thread performance. This was resolved by implementing rand_r() with thread-local seeds.

Data Visualization: The Python plotting script was generated to process the raw CSV data into comparative graphs.
