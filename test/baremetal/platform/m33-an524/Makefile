# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
#
# Makefile for m33-an524 Bare-Metal Testing
#
# Target: Cortex-M33 on mps3-an524 (QEMU)
# Memory: 512KB Flash @ 0x10000000, 512KB SRAM @ 0x38000000
#
# Prerequisites: Build ML-DSA libraries first:
#   make lib EXTRA_MAKEFILE=test/baremetal/platform/m33-an524/platform.mk OPT=0

PLATFORM_PATH := .
CROSS_PREFIX := arm-none-eabi-
CC := $(CROSS_PREFIX)gcc
OBJCOPY := $(CROSS_PREFIX)objcopy

# Cortex-M33 architecture flags
ARCH_FLAGS := -mcpu=cortex-m33 -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16

CFLAGS := \
	-O3 -Wall -Wextra \
	-fno-common -ffunction-sections -fdata-sections \
	-DARMCM33 \
	-DSEMIHOSTING \
	-I$(PLATFORM_PATH) \
	$(ARCH_FLAGS) \
	--specs=nosys.specs

LDFLAGS := \
	-Wl,--gc-sections \
	-Wl,--wrap=_open -Wl,--wrap=_close -Wl,--wrap=_read -Wl,--wrap=_write \
	-Wl,--wrap=_fstat -Wl,--wrap=_getpid -Wl,--wrap=_isatty \
	-Wl,--wrap=_kill -Wl,--wrap=_lseek -Wl,--wrap=main \
	-Wl,--no-warn-rwx-segments \
	-ffreestanding -T$(PLATFORM_PATH)/m33-an524.ld \
	$(ARCH_FLAGS)

# Library and include paths
LIB_PATH := ../../../../test/build
INC_FLAGS := -I../../../../mldsa -I../../../notrandombytes
NOTRAND_SRC := ../../../notrandombytes/notrandombytes.c

#==============================================================================
# Build Targets
#==============================================================================

all: hello.elf

# CMSIS modular source files
CMSIS_SOURCES := startup_ARMCM33.c system_ARMCM33.c semihosting.c

# Legacy test
test_lib.elf: test_lib.c $(CMSIS_SOURCES)
	$(CC) $(CFLAGS) -I../../../../mldsa $(LDFLAGS) -o $@ $^ $(LIB_PATH)/libmldsa44.a

# Functional tests - complete ML-DSA validation
comprehensive_func_test44.elf: comprehensive_func_test.c $(CMSIS_SOURCES) $(NOTRAND_SRC)
	$(CC) $(CFLAGS) -DMLD_CONFIG_PARAMETER_SET=44 $(INC_FLAGS) $(LDFLAGS) -o $@ $^ $(LIB_PATH)/libmldsa44.a

comprehensive_func_test65.elf: comprehensive_func_test.c $(CMSIS_SOURCES) $(NOTRAND_SRC)
	$(CC) $(CFLAGS) -DMLD_CONFIG_PARAMETER_SET=65 $(INC_FLAGS) $(LDFLAGS) -o $@ $^ $(LIB_PATH)/libmldsa65.a

comprehensive_func_test87.elf: comprehensive_func_test.c $(CMSIS_SOURCES) $(NOTRAND_SRC)
	$(CC) $(CFLAGS) -DMLD_CONFIG_PARAMETER_SET=87 $(INC_FLAGS) $(LDFLAGS) -o $@ $^ $(LIB_PATH)/libmldsa87.a

func_all: comprehensive_func_test44.elf comprehensive_func_test65.elf comprehensive_func_test87.elf

# Benchmarks - performance measurement
bench_baseline44.elf: bench_baseline.c $(CMSIS_SOURCES) $(NOTRAND_SRC)
	$(CC) $(CFLAGS) -DMLD_CONFIG_PARAMETER_SET=44 $(INC_FLAGS) $(LDFLAGS) -o $@ $^ $(LIB_PATH)/libmldsa44.a

bench_baseline65.elf: bench_baseline.c $(CMSIS_SOURCES) $(NOTRAND_SRC)
	$(CC) $(CFLAGS) -DMLD_CONFIG_PARAMETER_SET=65 $(INC_FLAGS) $(LDFLAGS) -o $@ $^ $(LIB_PATH)/libmldsa65.a

bench_baseline87.elf: bench_baseline.c $(CMSIS_SOURCES) $(NOTRAND_SRC)
	$(CC) $(CFLAGS) -DMLD_CONFIG_PARAMETER_SET=87 $(INC_FLAGS) $(LDFLAGS) -o $@ $^ $(LIB_PATH)/libmldsa87.a

bench_all: bench_baseline44.elf bench_baseline65.elf bench_baseline87.elf

#==============================================================================
# Run Targets (via QEMU)
#==============================================================================

run: hello.elf
	python3 exec_wrapper.py hello.elf

run_func44: comprehensive_func_test44.elf
	python3 exec_wrapper.py $<

run_func65: comprehensive_func_test65.elf
	python3 exec_wrapper.py $<

run_func87: comprehensive_func_test87.elf
	python3 exec_wrapper.py $<

run_func_all: func_all
	@echo "=== ML-DSA-44 Functional Test ===" && python3 exec_wrapper.py comprehensive_func_test44.elf
	@echo "=== ML-DSA-65 Functional Test ===" && python3 exec_wrapper.py comprehensive_func_test65.elf
	@echo "=== ML-DSA-87 Functional Test ===" && python3 exec_wrapper.py comprehensive_func_test87.elf

run_bench44: bench_baseline44.elf
	python3 exec_wrapper.py $<

run_bench65: bench_baseline65.elf
	python3 exec_wrapper.py $<

run_bench87: bench_baseline87.elf
	python3 exec_wrapper.py $<

run_bench_all: bench_all
	@echo "=== ML-DSA-44 Benchmark ===" && python3 exec_wrapper.py bench_baseline44.elf
	@echo "=== ML-DSA-65 Benchmark ===" && python3 exec_wrapper.py bench_baseline65.elf
	@echo "=== ML-DSA-87 Benchmark ===" && python3 exec_wrapper.py bench_baseline87.elf

#==============================================================================
# Utility
#==============================================================================

clean:
	rm -f *.elf

.PHONY: all func_all bench_all run run_func44 run_func65 run_func87 run_func_all \
        run_bench44 run_bench65 run_bench87 run_bench_all clean
