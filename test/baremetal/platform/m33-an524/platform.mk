# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
#
# Platform configuration for Cortex-M33 on mps3-an524 (QEMU)

PLATFORM_PATH := test/baremetal/platform/m33-an524

CROSS_PREFIX = arm-none-eabi-
CC = gcc

ARCH_FLAGS := -mcpu=cortex-m33 -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16

CFLAGS += \
	-O3 -Wall -Wextra -Wshadow \
	-Wno-pedantic -Wno-redundant-decls -Wno-missing-prototypes \
	-fno-common -ffunction-sections -fdata-sections \
	-DARMCM33 \
	-DSEMIHOSTING \
	-I$(PLATFORM_PATH) \
	$(ARCH_FLAGS) --specs=nosys.specs

CFLAGS += $(CFLAGS_EXTRA)

LDSCRIPT := $(PLATFORM_PATH)/m33-an524.ld

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

# Extra sources to be included in test binaries
EXTRA_SOURCES = $(PLATFORM_PATH)/startup_ARMCM33.c $(PLATFORM_PATH)/system_ARMCM33.c $(PLATFORM_PATH)/semihosting.c
# The CMSIS files fail compilation if conversion warnings are enabled
EXTRA_SOURCES_CFLAGS = -Wno-conversion -Wno-sign-conversion

EXEC_WRAPPER := $(realpath $(PLATFORM_PATH)/exec_wrapper.py)
