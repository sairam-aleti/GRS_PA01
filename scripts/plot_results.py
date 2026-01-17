import pandas as pd
import matplotlib.pyplot as plt
import os
import sys

# Configuration
RESULTS_DIR = "./results"
FILE_C = os.path.join(RESULTS_DIR, "MT25038_Part_C_CSV.csv")
FILE_D = os.path.join(RESULTS_DIR, "MT25038_Part_D_CSV.csv")
OUTPUT_DIR = "./plots"

def generate_plots():
    # 1. Validation
    if not os.path.exists(FILE_C) or not os.path.exists(FILE_D):
        print(f"Error: Could not find CSV files in {RESULTS_DIR}")
        print("Run ./scripts/benchmark.sh first!")
        return

    # 2. Read Data
    try:
        df_c = pd.read_csv(FILE_C) # Process Data
        df_d = pd.read_csv(FILE_D) # Thread Data
    except Exception as e:
        print(f"Error parsing CSVs: {e}")
        return

    # Combine for processing
    df = pd.concat([df_c, df_d])

    # Clean the '%' from CPU column if present
    if 'CPU_Percent' in df.columns:
        df['CPU_Percent'] = df['CPU_Percent'].astype(str).str.replace('%', '')
        df['CPU_Percent'] = pd.to_numeric(df['CPU_Percent'], errors='coerce')

    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    # 3. Plotting Loop (Time Comparison)
    metrics = ['Time_Seconds'] # We plot Time as the main requirement for Part D
    worker_types = ['cpu', 'mem', 'io']

    for metric in metrics:
        for w_type in worker_types:
            plt.figure(figsize=(10, 6))
            
            # Filter Data
            subset = df[df['Type'] == w_type]
            proc_data = subset[subset['Model'] == 'Process'].sort_values('Count')
            thread_data = subset[subset['Model'] == 'Thread'].sort_values('Count')

            if proc_data.empty or thread_data.empty:
                print(f"Skipping plot for {w_type} (no data found)")
                continue

            # Plot Lines
            plt.plot(proc_data['Count'], proc_data[metric], 
                     marker='o', label='Process (fork)', color='blue', linewidth=2)
            plt.plot(thread_data['Count'], thread_data[metric], 
                     marker='x', label='Thread (pthread)', color='red', linestyle='--', linewidth=2)

            # Styling
            plt.title(f"Scalability Analysis: {w_type.upper()} Task ({metric})", fontsize=14)
            plt.xlabel("Number of Workers (Count)", fontsize=12)
            plt.ylabel("Execution Time (Seconds)", fontsize=12)
            plt.grid(True, which="both", ls="-", alpha=0.3)
            plt.legend()
            
            # CRITICAL: Log Scale for X-axis because counts are 1, 2, 4, 8...
            plt.xscale('log', base=2)
            plt.xticks(proc_data['Count'], proc_data['Count']) # Force integer ticks

            # Save
            filename = f"{OUTPUT_DIR}/MT25038_Plot_{w_type}_{metric}.png"
            plt.savefig(filename)
            print(f"Generated: {filename}")
            plt.close()

if __name__ == "__main__":
    generate_plots()