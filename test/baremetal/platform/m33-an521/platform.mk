# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
#
# Platform configuration for Cortex-M33 on MPS2-AN521 (QEMU)

PLATFORM_PATH := test/baremetal/platform/m33-an521

CROSS_PREFIX = arm-none-eabi-
CC = gcc

ARCH_FLAGS := -mcpu=cortex-m33 -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16

CFLAGS += \
	-O3 -Wall -Wextra -Wshadow \
	-Wno-pedantic -Wno-redundant-decls -Wno-missing-prototypes \
	-fno-common -ffunction-sections -fdata-sections \
	-DSEMIHOSTING -DUSE_WRAPPED_MAIN \
	$(ARCH_FLAGS) --specs=nano.specs

CFLAGS += $(CFLAGS_EXTRA)

LDSCRIPT := $(PLATFORM_PATH)/m33-an521.ld

LDFLAGS += \
	-Wl,--gc-sections -Wl,--no-warn-rwx-segments -L. \
	--specs=nano.specs -Wl,--wrap=main \
	-ffreestanding -T$(LDSCRIPT) $(ARCH_FLAGS)

EXTRA_SOURCES := $(PLATFORM_PATH)/startup.c
EXTRA_SOURCES_CFLAGS := -Wno-conversion -Wno-sign-conversion

EXEC_WRAPPER := $(realpath $(PLATFORM_PATH)/exec_wrapper.py)
