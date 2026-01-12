# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
#
# Platform-specific makefile for MPS3-AN524 (Cortex-M33)
# Based on pqmx mps3-an547.mk, adapted for Cortex-M33 and AN524 requirements
#
# This file provides the hardware abstraction layer (HAL) configuration
# for the MPS3-AN524 platform with Dual Cortex-M33 processors.

ifndef _MPS3_AN524_HAL
_MPS3_AN524_HAL :=

# Toolchain configuration
CROSS_PREFIX ?= arm-none-eabi
RETAINED_VARS += CROSS_PREFIX

CC := $(CROSS_PREFIX)-gcc
AR := $(CROSS_PREFIX)-gcc-ar
LD := $(CC)
OBJCOPY := $(CROSS_PREFIX)-objcopy
SIZE := $(CROSS_PREFIX)-size

SYSROOT := $(shell $(CC) --print-sysroot)

# Preprocessor flags
CPPFLAGS += \
	--sysroot=$(SYSROOT) \
	-DARMCM33 \
	-DDEVICE=an524 \
	-DSEMIHOSTING

# Architecture flags for Cortex-M33
# - mcpu=cortex-m33: Target Cortex-M33 processor
# - mthumb: Generate Thumb instructions
# - mfloat-abi=hard: Use hardware floating point
# - mfpu=fpv5-sp-d16: Single-precision FPU (Cortex-M33 compatible)
ARCH_FLAGS += \
	-mcpu=cortex-m33 \
	-mthumb \
	-mfloat-abi=hard \
	-mfpu=fpv5-sp-d16

# Include platform directory
CPPFLAGS += \
	-I$(PLATFORM_PATH)

# Compiler flags
CFLAGS += \
	$(ARCH_FLAGS) \
	--specs=nosys.specs

# Linker script
LDSCRIPT = $(PLATFORM_PATH)/m33-an524.ld

# Linker flags with syscall wrapping for semihosting
LDFLAGS += \
	--specs=nosys.specs \
	-Wl,--wrap=_open \
	-Wl,--wrap=_close \
	-Wl,--wrap=_read \
	-Wl,--wrap=_write \
	-Wl,--wrap=_fstat \
	-Wl,--wrap=_getpid \
	-Wl,--wrap=_isatty \
	-Wl,--wrap=_kill \
	-Wl,--wrap=_lseek \
	-Wl,--wrap=main \
	-ffreestanding \
	-T$(LDSCRIPT) \
	$(ARCH_FLAGS)

# HAL source files - complete CMSIS-compliant platform
HAL_SRC += \
	$(PLATFORM_PATH)/startup_ARMCM33.c \
	$(PLATFORM_PATH)/system_ARMCM33.c \
	$(PLATFORM_PATH)/semihosting.c \
	$(PLATFORM_PATH)/uart.c \
	$(PLATFORM_PATH)/cmdline.c \
	$(PLATFORM_PATH)/libfns.c

HAL_OBJ = $(call objs,$(HAL_SRC))

OBJ += $(HAL_OBJ)

libhal.a: $(HAL_OBJ)

LDLIBS += -lhal
LIBDEPS += libhal.a
TARGETS += libhal.a

endif
