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

# Create/Reset the CSV file with headers
echo "Model,Type,Count,Time_Seconds" > "$RESULTS_FILE"

echo "Starting Benchmark for Roll No: MT25038..."
echo "Saving results to: $RESULTS_FILE"

# Define the test parameters
# We use powers of 2 for scaling, plus '8' (your roll digit)
COUNTS=(1 2 4 8 16 32 64)
TYPES=("cpu" "mem" "io")


# FUNCTION: Run Test
# Arguments: $1=ModelName $2=Executable $3=Type $4=Count

run_test() {
    local model=$1
    local exe=$2
    local type=$3
    local count=$4

    # Print status to console (without newline) to show progress
    echo -n "Running $model | Type: $type | Count: $count ... "

    # Run the program and capture output
    # 2>&1 redirects stderr to stdout so we capture everything
    output=$($exe $type $count 2>&1)

    # Parse the time using grep and awk
    # Expected output format: "[Manager] ... Total time: 0.1234 seconds."
    # We grep for "Total time", then print the word immediately before "seconds"
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


# MAIN LOOPS

# Loop 1: Processes
for t in "${TYPES[@]}"; do
    for c in "${COUNTS[@]}"; do
        run_test "Process" "$BIN_DIR/process_mgr" "$t" "$c"
    done
done

# Loop 2: Threads
for t in "${TYPES[@]}"; do
    for c in "${COUNTS[@]}"; do
        run_test "Thread" "$BIN_DIR/thread_mgr" "$t" "$c"
    done
done

echo "------------------------------------------------"
echo "Benchmark Complete."