# Makefile
# --------
# Description: Automates the compilation of Process and Thread managers.
# Usage:
#   make          -> Compiles everything
#   make clean    -> Removes binaries and object files

# Compiler and Flags
CC = gcc
# -Iinclude: Look for headers in the 'include' folder
# -Wall -Wextra: Enable all warnings (Professional standard)
# -O2: Optimize code (Critical for performance benchmarking)
# -pthread: Enable threading support
CFLAGS = -Wall -Wextra -O2 -Iinclude -pthread 

# Directories
SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = bin

# Targets (The programs we want to build)
TARGET_PROCESS = $(BIN_DIR)/process_mgr
TARGET_THREAD  = $(BIN_DIR)/thread_mgr

# Source Files
SRCS_COMMON  = $(SRC_DIR)/workers.c
SRCS_PROCESS = $(SRC_DIR)/process_mgr.c
SRCS_THREAD  = $(SRC_DIR)/thread_mgr.c

# Object Files (Compiled intermediate files)
OBJS_COMMON  = $(OBJ_DIR)/workers.o
OBJS_PROCESS = $(OBJ_DIR)/process_mgr.o
OBJS_THREAD  = $(OBJ_DIR)/thread_mgr.o

# RULES

# Default rule: Build both programs
all: directories $(TARGET_PROCESS) $(TARGET_THREAD)

# 1. Create Output Directories (if they don't exist)
directories:
	@mkdir -p $(OBJ_DIR)
	@mkdir -p $(BIN_DIR)

# 2. Build the Worker Library (The Engine)
$(OBJS_COMMON): $(SRCS_COMMON)
	@echo "Compiling Worker Library..."
	$(CC) $(CFLAGS) -c $< -o $@

# 3. Build Process Manager (Program A)
$(TARGET_PROCESS): $(SRCS_PROCESS) $(OBJS_COMMON)
	@echo "Linking Process Manager..."
	# Compile process_mgr.c to .o
	$(CC) $(CFLAGS) -c $(SRCS_PROCESS) -o $(OBJS_PROCESS)
	# Link everything together
	$(CC) $(CFLAGS) $(OBJS_PROCESS) $(OBJS_COMMON) -o $@

# 4. Build Thread Manager (Program B)
$(TARGET_THREAD): $(SRCS_THREAD) $(OBJS_COMMON)
	@echo "Linking Thread Manager..."
	# Compile thread_mgr.c to .o
	$(CC) $(CFLAGS) -c $(SRCS_THREAD) -o $(OBJS_THREAD)
	# Link everything together
	$(CC) $(CFLAGS) $(OBJS_THREAD) $(OBJS_COMMON) -o $@

# Cleanup Rule
clean:
	@echo "Cleaning up..."
	rm -rf $(OBJ_DIR)/*.o
	rm -rf $(BIN_DIR)/*

.PHONY: all clean directories