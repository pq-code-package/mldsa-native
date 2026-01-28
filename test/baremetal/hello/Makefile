# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
#
# Makefile for incremental platform validation tests.
# These tests help isolate platform setup issues from ML-DSA complexity.
#
# Usage (from repository root):
#   nix develop .#arm-embedded
#   make -f test/baremetal/hello/Makefile hello
#   make -f test/baremetal/hello/Makefile run_hello
#
# Test progression:
#   1. hello      - Basic platform validation (printf, stack pointer)
#   2. stack_test - Stack usage measurement
#   3. (then run ML-DSA tests if all above pass)
#
# Note: ML-DSA uses static allocation (no heap), so stack is the key resource.

# Platform configuration
PLATFORM_MK := test/baremetal/platform/m33-an524/platform.mk
include $(PLATFORM_MK)

# Build directory
BUILD_DIR := test/build/hello

# Source files
HELLO_SRC := test/baremetal/hello/hello.c
STACK_SRC := test/baremetal/hello/stack_test.c
MLDSA_STACK_SRC := test/baremetal/hello/mldsa_stack_test.c

# Output binaries
HELLO_BIN := $(BUILD_DIR)/hello_m33_an524
STACK_BIN := $(BUILD_DIR)/stack_test_m33_an524
MLDSA_STACK_BIN_44 := $(BUILD_DIR)/mldsa_stack_44
MLDSA_STACK_BIN_65 := $(BUILD_DIR)/mldsa_stack_65
MLDSA_STACK_BIN_87 := $(BUILD_DIR)/mldsa_stack_87

# Remove duplicate --specs=nosys.specs from LDFLAGS (already in CFLAGS)
# This avoids "attempt to rename spec" error when both are passed to gcc
LDFLAGS_CLEAN := $(filter-out --specs=nosys.specs,$(LDFLAGS))

# ML-DSA library paths
MLDSA_LIB_44 := test/build/libmldsa44.a
MLDSA_LIB_65 := test/build/libmldsa65.a
MLDSA_LIB_87 := test/build/libmldsa87.a

# ML-DSA include path
MLDSA_INC := -Imldsa

# notrandombytes for deterministic testing
NOTRANDOMBYTES_SRC := test/notrandombytes/notrandombytes.c
NOTRANDOMBYTES_OBJ := $(BUILD_DIR)/notrandombytes.o

# Default target
.PHONY: all
all: hello stack_test

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile platform sources to objects
PLATFORM_OBJS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(notdir $(EXTRA_SOURCES)))

$(BUILD_DIR)/%.o: $(CMSIS_PATH)/%.c | $(BUILD_DIR)
	$(CROSS_PREFIX)$(CC) $(CFLAGS) $(EXTRA_SOURCES_CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: $(PLATFORM_PATH)/%.c | $(BUILD_DIR)
	$(CROSS_PREFIX)$(CC) $(CFLAGS) $(EXTRA_SOURCES_CFLAGS) -c -o $@ $<

# Hello world test
.PHONY: hello
hello: $(HELLO_BIN)

$(HELLO_BIN): $(HELLO_SRC) $(PLATFORM_OBJS) | $(BUILD_DIR)
	$(CROSS_PREFIX)$(CC) $(CFLAGS) $(LDFLAGS_CLEAN) -o $@ $< $(PLATFORM_OBJS)

.PHONY: run_hello
run_hello: $(HELLO_BIN)
	@echo "=== Running Hello World Test ==="
	$(EXEC_WRAPPER) $(HELLO_BIN)

# Stack test
.PHONY: stack_test
stack_test: $(STACK_BIN)

$(STACK_BIN): $(STACK_SRC) $(PLATFORM_OBJS) | $(BUILD_DIR)
	$(CROSS_PREFIX)$(CC) $(CFLAGS) $(LDFLAGS_CLEAN) -o $@ $< $(PLATFORM_OBJS)

.PHONY: run_stack_test
run_stack_test: $(STACK_BIN)
	@echo "=== Running Stack Test ==="
	$(EXEC_WRAPPER) $(STACK_BIN)

# ML-DSA stack measurement tests
# These require the ML-DSA libraries to be built first with:
#   make lib EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0

# Build notrandombytes object
$(NOTRANDOMBYTES_OBJ): $(NOTRANDOMBYTES_SRC) | $(BUILD_DIR)
	$(CROSS_PREFIX)$(CC) $(CFLAGS) -Itest/notrandombytes -c -o $@ $<

.PHONY: mldsa_stack_44
mldsa_stack_44: $(MLDSA_STACK_BIN_44)

$(MLDSA_STACK_BIN_44): $(MLDSA_STACK_SRC) $(PLATFORM_OBJS) $(NOTRANDOMBYTES_OBJ) $(MLDSA_LIB_44) | $(BUILD_DIR)
	$(CROSS_PREFIX)$(CC) $(CFLAGS) $(MLDSA_INC) -DMLD_CONFIG_PARAMETER_SET=44 $(LDFLAGS_CLEAN) -o $@ $< $(PLATFORM_OBJS) $(NOTRANDOMBYTES_OBJ) $(MLDSA_LIB_44)

.PHONY: run_mldsa_stack_44
run_mldsa_stack_44: $(MLDSA_STACK_BIN_44)
	@echo "=== Running ML-DSA-44 Stack Measurement ==="
	$(EXEC_WRAPPER) $(MLDSA_STACK_BIN_44)

.PHONY: mldsa_stack_65
mldsa_stack_65: $(MLDSA_STACK_BIN_65)

$(MLDSA_STACK_BIN_65): $(MLDSA_STACK_SRC) $(PLATFORM_OBJS) $(NOTRANDOMBYTES_OBJ) $(MLDSA_LIB_65) | $(BUILD_DIR)
	$(CROSS_PREFIX)$(CC) $(CFLAGS) $(MLDSA_INC) -DMLD_CONFIG_PARAMETER_SET=65 $(LDFLAGS_CLEAN) -o $@ $< $(PLATFORM_OBJS) $(NOTRANDOMBYTES_OBJ) $(MLDSA_LIB_65)

.PHONY: run_mldsa_stack_65
run_mldsa_stack_65: $(MLDSA_STACK_BIN_65)
	@echo "=== Running ML-DSA-65 Stack Measurement ==="
	$(EXEC_WRAPPER) $(MLDSA_STACK_BIN_65)

.PHONY: mldsa_stack_87
mldsa_stack_87: $(MLDSA_STACK_BIN_87)

$(MLDSA_STACK_BIN_87): $(MLDSA_STACK_SRC) $(PLATFORM_OBJS) $(NOTRANDOMBYTES_OBJ) $(MLDSA_LIB_87) | $(BUILD_DIR)
	$(CROSS_PREFIX)$(CC) $(CFLAGS) $(MLDSA_INC) -DMLD_CONFIG_PARAMETER_SET=87 $(LDFLAGS_CLEAN) -o $@ $< $(PLATFORM_OBJS) $(NOTRANDOMBYTES_OBJ) $(MLDSA_LIB_87)

.PHONY: run_mldsa_stack_87
run_mldsa_stack_87: $(MLDSA_STACK_BIN_87)
	@echo "=== Running ML-DSA-87 Stack Measurement ==="
	$(EXEC_WRAPPER) $(MLDSA_STACK_BIN_87)

# Run all ML-DSA stack measurements
.PHONY: run_mldsa_stack_all
run_mldsa_stack_all: run_mldsa_stack_44 run_mldsa_stack_65 run_mldsa_stack_87

# Run all tests in sequence
.PHONY: run_all
run_all: run_hello run_stack_test
	@echo ""
	@echo "=== All Platform Validation Tests Passed ==="
	@echo "Platform is ready for ML-DSA testing."
	@echo ""
	@echo "Next steps:"
	@echo "  make run_func_44 EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0"

# Clean
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

# Help
.PHONY: help
help:
	@echo "Incremental Platform Validation Tests for Cortex-M33 MPS3-AN524"
	@echo ""
	@echo "Build targets:"
	@echo "  hello          - Build hello world test"
	@echo "  stack_test     - Build stack usage test"
	@echo "  mldsa_stack_44 - Build ML-DSA-44 stack measurement"
	@echo "  mldsa_stack_65 - Build ML-DSA-65 stack measurement"
	@echo "  mldsa_stack_87 - Build ML-DSA-87 stack measurement"
	@echo "  all            - Build basic tests (hello, stack_test)"
	@echo ""
	@echo "Run targets:"
	@echo "  run_hello          - Run hello world test"
	@echo "  run_stack_test     - Run stack usage test"
	@echo "  run_mldsa_stack_44 - Run ML-DSA-44 stack measurement"
	@echo "  run_mldsa_stack_65 - Run ML-DSA-65 stack measurement"
	@echo "  run_mldsa_stack_87 - Run ML-DSA-87 stack measurement"
	@echo "  run_mldsa_stack_all - Run all ML-DSA stack measurements"
	@echo "  run_all            - Run basic validation tests"
	@echo ""
	@echo "Other:"
	@echo "  clean       - Remove build artifacts"
	@echo "  help        - Show this help"
	@echo ""
	@echo "Note: ML-DSA stack tests require libraries to be built first:"
	@echo "  make lib EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0"
	@echo ""
	@echo "Usage:"
	@echo "  nix develop .#arm-embedded"
	@echo "  make -f test/baremetal/hello/Makefile run_mldsa_stack_all"
