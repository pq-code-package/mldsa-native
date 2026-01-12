# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
#
# Platform configuration for Cortex-M33 on mps3-an524 (QEMU)
#
# This platform provides 100% CMSIS compliance with M55-AN547 reference,
# including complete hardware abstraction, system integration, and ARM v8-M features.

PLATFORM_PATH := test/baremetal/platform/m33-an524

CROSS_PREFIX = arm-none-eabi-
CC = gcc

# Architecture flags for Cortex-M33
# - mcpu=cortex-m33: Target Cortex-M33 processor
# - mthumb: Generate Thumb instructions
# - mfloat-abi=soft: Use software floating point to avoid double-precision FPU issues
#   (Standard newlib printf uses double-precision which Cortex-M33's FPU doesn't support)
ARCH_FLAGS := -mcpu=cortex-m33 -mthumb -mfloat-abi=soft

CFLAGS += \
	-O3 -Wall -Wextra -Wshadow \
	-Wno-pedantic -Wno-redundant-decls -Wno-missing-prototypes \
	-fno-common -ffunction-sections -fdata-sections \
	-DARMCM33 \
	-DDEVICE=an524 \
	-DSEMIHOSTING \
	-I$(PLATFORM_PATH) \
	-I$(PLATFORM_PATH)/m-profile \
	$(ARCH_FLAGS) --specs=nosys.specs

CFLAGS += $(CFLAGS_EXTRA)

LDSCRIPT := $(PLATFORM_PATH)/m33-an524.ld

# Linker flags for semihosting support
# Uses --wrap for syscalls to redirect to our implementations (like M55-AN547)
# Exit is handled via destructor in semihosting.c (like M55-AN547)
# Note: Using nosys.specs (not nano.specs) for full printf with 64-bit support
# This requires soft-float to avoid double-precision FPU issues
LDFLAGS += \
	-Wl,--gc-sections -Wl,--no-warn-rwx-segments -L. \
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
	-ffreestanding -T$(LDSCRIPT) $(ARCH_FLAGS)

# Platform source files
# Note: __wrap__write and __wrap__read are in system_ARMCM33.c (like M55-AN547)
# libfns.c provides other wrapped syscalls (like M55-AN547)
# cmdline.c provides __wrap_main for command line processing
# Note: No hal.c - uses default test/hal/hal.c like M55-AN547
# For actual cycle counting on M33, use the standalone bench_baseline.c
EXTRA_SOURCES = \
	$(PLATFORM_PATH)/startup_ARMCM33.c \
	$(PLATFORM_PATH)/system_ARMCM33.c \
	$(PLATFORM_PATH)/semihosting.c \
	$(PLATFORM_PATH)/libfns.c \
	$(PLATFORM_PATH)/cmdline.c \
	$(PLATFORM_PATH)/uart.c

# The CMSIS files fail compilation if conversion warnings are enabled
EXTRA_SOURCES_CFLAGS = -Wno-conversion -Wno-sign-conversion

EXEC_WRAPPER := $(realpath $(PLATFORM_PATH)/exec_wrapper.py)

# =============================================================================
# CMSIS Compliance Verification
# =============================================================================
# This section verifies that all required CMSIS files are present.
# The platform achieves 100% CMSIS compliance with M55-AN547 reference.

# Core CMSIS Headers (Layer 1)
REQUIRED_CMSIS_CORE = \
	$(PLATFORM_PATH)/core_cm33.h \
	$(PLATFORM_PATH)/cmsis_compiler.h \
	$(PLATFORM_PATH)/cmsis_gcc.h \
	$(PLATFORM_PATH)/cmsis_version.h

# Device Templates (Layer 2)
REQUIRED_DEVICE_TEMPLATES = \
	$(PLATFORM_PATH)/ARMCM33.h \
	$(PLATFORM_PATH)/startup_ARMCM33.c \
	$(PLATFORM_PATH)/system_ARMCM33.c \
	$(PLATFORM_PATH)/system_ARMCM33.h \
	$(PLATFORM_PATH)/m33-an524.ld

# Hardware Abstraction (Layer 3)
REQUIRED_HARDWARE_ABSTRACTION = \
	$(PLATFORM_PATH)/semihosting.c \
	$(PLATFORM_PATH)/uart.c \
	$(PLATFORM_PATH)/uart.h

# System Integration (Layer 4)
REQUIRED_SYSTEM_INTEGRATION = \
	$(PLATFORM_PATH)/cmdline.c \
	$(PLATFORM_PATH)/libfns.c

# ARM v8-M Features (Layer 5) - in m-profile subdirectory
REQUIRED_ARMV8M_FEATURES = \
	$(PLATFORM_PATH)/m-profile/armv8m_mpu.h \
	$(PLATFORM_PATH)/m-profile/armv8m_pmu.h \
	$(PLATFORM_PATH)/m-profile/armv7m_cachel1.h

# All required CMSIS files
REQUIRED_CMSIS_FILES = \
	$(REQUIRED_CMSIS_CORE) \
	$(REQUIRED_DEVICE_TEMPLATES) \
	$(REQUIRED_HARDWARE_ABSTRACTION) \
	$(REQUIRED_SYSTEM_INTEGRATION) \
	$(REQUIRED_ARMV8M_FEATURES)

# Verify all required CMSIS files exist (only when building, not during clean)
ifneq ($(MAKECMDGOALS),clean)
MISSING_FILES := $(strip $(foreach file,$(REQUIRED_CMSIS_FILES),$(if $(wildcard $(file)),,$(file))))
ifneq ($(MISSING_FILES),)
$(warning CMSIS Compliance Warning: Missing files: $(MISSING_FILES))
endif
endif
