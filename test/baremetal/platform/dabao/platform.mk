# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# Dabao board (Baochip-1x, VexRiscv RV32IMAC @ 350 MHz).
#
# Test binaries are compiled with a riscv32 newlib toolchain and linked into
# the Xous `baremetal` image, which provides the USB serial console. The link
# step (link.py) produces a signed UF2 image in place of the usual ELF, and
# exec_wrapper.py flashes and runs it through the boot1 console.

PLATFORM_PATH := test/baremetal/platform/dabao

CROSS_PREFIX = riscv32-none-elf-
CC = gcc

DABAO_ARCHFLAGS := -march=rv32imac_zicsr_zifencei -mabi=ilp32

CFLAGS += $(DABAO_ARCHFLAGS)

# Benchmark iteration counts sized for a 350 MHz core
CFLAGS += -DMLD_BENCHMARK_NTESTS=10 -DMLD_BENCHMARK_NITERATIONS=10 -DMLD_BENCHMARK_NWARMUP=10

CFLAGS += \
	-O3 \
	-Wall -Wextra -Wshadow \
	-Wno-pedantic \
	-Wno-redundant-decls \
	-Wno-missing-prototypes \
	-Wno-conversion \
	-Wno-sign-conversion \
	-fno-common \
	-ffunction-sections \
	-fdata-sections

CFLAGS += $(CFLAGS_EXTRA)

# The final link is done by rustc; hand it newlib and libgcc explicitly.
DABAO_LIBS := $(foreach lib,libc.a libgcc.a,$(shell $(CROSS_PREFIX)$(CC) $(DABAO_ARCHFLAGS) -print-file-name=$(lib)))
LDLIBS += $(DABAO_LIBS)

override LD := python3 $(abspath $(PLATFORM_PATH)/link.py)
export DABAO_LD = $(CROSS_PREFIX)ld
export DABAO_OBJCOPY = $(OBJCOPY)

EXTRA_SOURCES = $(PLATFORM_PATH)/dabao.c

# Patched xous-core checkout used for the link; link.py fetches it on demand.
XOUS_CORE ?= $(abspath $(or $(BUILD_DIR),test/build)/xous-core)
export XOUS_CORE

EXEC_WRAPPER := $(abspath $(PLATFORM_PATH)/exec_wrapper.py)
