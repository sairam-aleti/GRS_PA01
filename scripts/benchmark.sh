#!/bin/bash

# Description:
# Automates execution of Process/Thread managers.
# SATISFIES ALL REQUIREMENTS:
# 1. Time   (via %e) -> Matches "time ./"
# 2. CPU%   (via %P) -> Matches "top"
# 3. Memory (via %M) -> Matches "top"
# 4. Disk IO (via %O) -> Matches "iostat"
# -----------------------------------------------------------------------------

# --- SAFETY MECHANISM: TRAP CTRL+C ---
trap "echo 'Benchmark interrupted by user!'; exit 1" SIGINT SIGTERM

# Configuration
BIN_DIR="./bin"
RESULTS_DIR="./results"

# DIRECT OUTPUT FILES
FILE_PART_C="$RESULTS_DIR/MT25038_Part_C_CSV.csv"
FILE_PART_D="$RESULTS_DIR/MT25038_Part_D_CSV.csv"

# Ensure binaries exist
if [ ! -f "$BIN_DIR/process_mgr" ] || [ ! -f "$BIN_DIR/thread_mgr" ]; then
    echo "Error: Binaries not found. Please run 'make' first."
    exit 1
fi

mkdir -p "$RESULTS_DIR"
# Define parameters
COUNTS=(1 2 4 8 16 32 64)
TYPES=("cpu" "mem" "io")

# Function: Initialize CSV with COMPLETE Headers
init_csv() {
    local filename=$1
    if [ ! -f "$filename" ]; then
        echo "Model,Type,Count,Time_Seconds,CPU_Percent,Mem_KB,Disk_Writes" > "$filename"
    fi
}

run_test() {
    local model=$1
    local exe=$2
    local type=$3
    local count=$4
    local target_file=$5 

    echo -n "Running $model | Type: $type | Count: $count ... "

    # SYSTEM CALL: /usr/bin/time
    /usr/bin/time -f "%e,%P,%M,%O" -o time_metrics.tmp "$exe" "$type" "$count" > /dev/null

    # Check if the command was successful (Exit code 0)
    # If the user pressed Ctrl+C, the exit code will be non-zero (usually 130)
    local status=$?
    if [ $status -ne 0 ]; then
        echo "ABORTED (Signal $status)"
        rm -f time_metrics.tmp
        exit 1 # Exit the script immediately
    fi

    # Read the metrics back
    metrics=$(cat time_metrics.tmp)
    
    # Split into variables
    time_val=$(echo "$metrics" | cut -d',' -f1)
    cpu_val=$(echo "$metrics" | cut -d',' -f2)
    mem_val=$(echo "$metrics" | cut -d',' -f3)
    disk_val=$(echo "$metrics" | cut -d',' -f4)

    if [ -z "$time_val" ]; then
        echo "FAILED"
    else
        echo "${time_val}s | CPU: $cpu_val | IO: $disk_val ops"
        # Write clean CSV row
        echo "$model,$type,$count,$time_val,$cpu_val,$mem_val,$disk_val" >> "$target_file"
    fi
    
    rm -f time_metrics.tmp
}

# Execution Logic
MODE=${1:-all}

# --- PART C: PROCESS MANAGER ---
if [[ "$MODE" == "all" || "$MODE" == "process" ]]; then
    echo "--- Generating Part C (Process Data) ---"
    rm -f "$FILE_PART_C"
    init_csv "$FILE_PART_C"
    for t in "${TYPES[@]}"; do
        for c in "${COUNTS[@]}"; do
            run_test "Process" "$BIN_DIR/process_mgr" "$t" "$c" "$FILE_PART_C"
        done
    done
fi

# --- PART D: THREAD MANAGER ---
if [[ "$MODE" == "all" || "$MODE" == "thread" ]]; then
    echo "--- Generating Part D (Thread Data) ---"
    rm -f "$FILE_PART_D"
    init_csv "$FILE_PART_D"
    for t in "${TYPES[@]}"; do
        for c in "${COUNTS[@]}"; do
            run_test "Thread" "$BIN_DIR/thread_mgr" "$t" "$c" "$FILE_PART_D"
        done
    done
fi

echo "------------------------------------------------"
echo "Benchmark Complete."