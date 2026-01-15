#!/bin/bash

# Description:
# Bash script to automate the execution of Process and Thread managers.
# It parses the "Total time" output and saves it to a CSV file.
# -----------------------------------------------------------------------------

# Configuration
BIN_DIR="./bin"
RESULTS_FILE="./results/benchmark_data.csv"

# Ensure binaries exist
if [ ! -f "$BIN_DIR/process_mgr" ] || [ ! -f "$BIN_DIR/thread_mgr" ]; then
    echo "Error: Binaries not found. Please run 'make' first."
    exit 1
fi

# 1. SMART HEADER: Only create header if file doesn't exist
if [ ! -f "$RESULTS_FILE" ]; then
    echo "Model,Type,Count,Time_Seconds" > "$RESULTS_FILE"
    echo "Created new results file: $RESULTS_FILE"
else
    echo "Appending to existing results file: $RESULTS_FILE"
fi

echo "Starting Benchmark for Roll No: MT25038..."

# Define the test parameters
COUNTS=(1 2 4 8 16 32 64)
TYPES=("cpu" "mem" "io")

# FUNCTION: Run Test
run_test() {
    local model=$1
    local exe=$2
    local type=$3
    local count=$4

    echo -n "Running $model | Type: $type | Count: $count ... "

    # Run and capture
    output=$($exe $type $count 2>&1)
    
    # Parse output for "Total time"
    time_taken=$(echo "$output" | grep "Total time" | awk '{print $(NF-1)}')

    if [ -z "$time_taken" ]; then
        echo "FAILED"
        echo "Debug output: $output"
    else
        echo "${time_taken}s"
        # Append to CSV
        echo "$model,$type,$count,$time_taken" >> "$RESULTS_FILE"
    fi
}

# SELECTION LOGIC: Check first argument ($1)
MODE=${1:-all} # Default to "all" if no argument provided

# Loop 1: Processes (Only if mode is 'all' or 'process')
if [[ "$MODE" == "all" || "$MODE" == "process" ]]; then
    echo "--- Benchmarking PROCESSES ---"
    for t in "${TYPES[@]}"; do
        for c in "${COUNTS[@]}"; do
            run_test "Process" "$BIN_DIR/process_mgr" "$t" "$c"
        done
    done
fi

# Loop 2: Threads (Only if mode is 'all' or 'thread')
if [[ "$MODE" == "all" || "$MODE" == "thread" ]]; then
    echo "--- Benchmarking THREADS ---"
    for t in "${TYPES[@]}"; do
        for c in "${COUNTS[@]}"; do
            run_test "Thread" "$BIN_DIR/thread_mgr" "$t" "$c"
        done
    done
fi

echo "------------------------------------------------"
echo "Benchmark Complete."