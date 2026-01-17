# Makefile for Roll No: MT25038
# -----------------------------------------------------------------------------
# Description:
# I have designed this Makefile to automate the compilation of my Process
# and Thread managers. It links my worker library to the respective main programs.
# -----------------------------------------------------------------------------

# I am defining my compiler and flags here.
# -pthread: Essential for my Thread Manager (Program B).
# -O2: I use Level 2 optimization to ensure my benchmark results are realistic.
CC = gcc
CFLAGS = -Wall -Wextra -O2 -pthread -Iinclude

# I am defining the source files according to the strict naming convention.
# Part A: Program A (Process Manager), Program B (Thread Manager), and my Workers Lib.
SRC_A = src/MT25038_Part_A_Program_A.c
SRC_B = src/MT25038_Part_A_Program_B.c
SRC_W = src/MT25038_Part_A_Workers.c

# Object Files (Intermediate compilation output)
OBJ_A = obj/Program_A.o
OBJ_B = obj/Program_B.o
OBJ_W = obj/Workers.o

# Binary Output Names
# I am keeping these standard so my benchmark scripts can find them easily.
BIN_A = bin/process_mgr
BIN_B = bin/thread_mgr

# -----------------------------------------------------------------------------
# Build Rules
# -----------------------------------------------------------------------------

# Default Target: I build both managers when 'make' is called.
all: directories $(BIN_A) $(BIN_B)

# Link Rule for Process Manager
# I link the Process Manager object with my Worker Library object.
$(BIN_A): $(OBJ_A) $(OBJ_W)
	@echo "[Builder] I am linking the Process Manager executable..."
	$(CC) $(CFLAGS) $^ -o $@

# Link Rule for Thread Manager
# I link the Thread Manager object with my Worker Library object.
$(BIN_B): $(OBJ_B) $(OBJ_W)
	@echo "[Builder] I am linking the Thread Manager executable..."
	$(CC) $(CFLAGS) $^ -o $@

# Compile Rule: Program A
# I compile the Process Manager source code into an object file.
$(OBJ_A): $(SRC_A)
	@echo "[Builder] I am compiling my Process Manager source..."
	$(CC) $(CFLAGS) -c $< -o $@

# Compile Rule: Program B
# I compile the Thread Manager source code into an object file.
$(OBJ_B): $(SRC_B)
	@echo "[Builder] I am compiling my Thread Manager source..."
	$(CC) $(CFLAGS) -c $< -o $@

# Compile Rule: Workers Library
# I compile the shared worker logic.
$(OBJ_W): $(SRC_W)
	@echo "[Builder] I am compiling my Worker Library..."
	$(CC) $(CFLAGS) -c $< -o $@

# Utility Rule: Directories
# I ensure the build directories exist before compiling.
directories:
	@mkdir -p obj bin results

# Utility Rule: Clean
# I clean up all artifacts to ensure a fresh build.
clean:
	@echo "[Builder] I am cleaning up build artifacts..."
	rm -rf obj bin results
	rm -f io_test_*.tmp

.PHONY: all clean directories