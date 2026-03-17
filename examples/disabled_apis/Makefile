# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

.PHONY: build run clean
.DEFAULT_GOAL := all

CC  ?= gcc

# Adjust CFLAGS if needed
CFLAGS := \
	-Wall \
	-Wextra \
	-Werror=unused-result \
	-Wpedantic \
	-Werror \
	-Wmissing-prototypes \
	-Wshadow \
	-Wpointer-arith \
	-Wredundant-decls \
	-Wconversion \
	-Wsign-conversion \
	-Wno-long-long \
	-Wno-unknown-pragmas \
	-Wno-unused-command-line-argument \
	-O3 \
	-fomit-frame-pointer \
	-std=c99 \
	-pedantic \
	-MMD \
	$(CFLAGS)

AUTO ?= 1
include auto.mk

# Append cross-prefix for cross compilation
ifeq (,$(findstring $(CROSS_PREFIX),$(CC)))
CC  := $(CROSS_PREFIX)$(CC)
endif

MLD_SOURCE=$(wildcard				\
	mldsa_native/src/*.c			\
	mldsa_native/src/**/*.c			\
	mldsa_native/src/**/**/*.c		\
	mldsa_native/src/**/**/**/*.c)

INC=-Imldsa_native
RNG_SOURCE=$(wildcard test_only_rng/*.c)
ALL_SOURCE=$(MLD_SOURCE) $(RNG_SOURCE) main.c

BUILD_DIR=build

CFLAGS += -DMLD_CONFIG_NAMESPACE_PREFIX=mldsa

# Disabled API flags
KEYGEN_ONLY_FLAGS = -DMLD_CONFIG_NO_SIGN_API -DMLD_CONFIG_NO_VERIFY_API
SIGN_ONLY_FLAGS   = -DMLD_CONFIG_NO_KEYPAIR_API -DMLD_CONFIG_NO_VERIFY_API
VERIFY_ONLY_FLAGS = -DMLD_CONFIG_NO_KEYPAIR_API -DMLD_CONFIG_NO_SIGN_API
SIGN_VERIFY_FLAGS = -DMLD_CONFIG_NO_KEYPAIR_API

# Per-target CFLAGS for each combination
$(BUILD_DIR)/test_keygen_only_44:  CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44 $(KEYGEN_ONLY_FLAGS)
$(BUILD_DIR)/test_keygen_only_65:  CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65 $(KEYGEN_ONLY_FLAGS)
$(BUILD_DIR)/test_keygen_only_87:  CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87 $(KEYGEN_ONLY_FLAGS)
$(BUILD_DIR)/test_sign_only_44:    CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44 $(SIGN_ONLY_FLAGS)
$(BUILD_DIR)/test_sign_only_65:    CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65 $(SIGN_ONLY_FLAGS)
$(BUILD_DIR)/test_sign_only_87:    CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87 $(SIGN_ONLY_FLAGS)
$(BUILD_DIR)/test_verify_only_44:  CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44 $(VERIFY_ONLY_FLAGS)
$(BUILD_DIR)/test_verify_only_65:  CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65 $(VERIFY_ONLY_FLAGS)
$(BUILD_DIR)/test_verify_only_87:  CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87 $(VERIFY_ONLY_FLAGS)
$(BUILD_DIR)/test_sign_verify_44:  CFLAGS += -DMLD_CONFIG_PARAMETER_SET=44 $(SIGN_VERIFY_FLAGS)
$(BUILD_DIR)/test_sign_verify_65:  CFLAGS += -DMLD_CONFIG_PARAMETER_SET=65 $(SIGN_VERIFY_FLAGS)
$(BUILD_DIR)/test_sign_verify_87:  CFLAGS += -DMLD_CONFIG_PARAMETER_SET=87 $(SIGN_VERIFY_FLAGS)

ALL_BINARIES = \
	$(BUILD_DIR)/test_keygen_only_44 \
	$(BUILD_DIR)/test_keygen_only_65 \
	$(BUILD_DIR)/test_keygen_only_87 \
	$(BUILD_DIR)/test_sign_only_44 \
	$(BUILD_DIR)/test_sign_only_65 \
	$(BUILD_DIR)/test_sign_only_87 \
	$(BUILD_DIR)/test_verify_only_44 \
	$(BUILD_DIR)/test_verify_only_65 \
	$(BUILD_DIR)/test_verify_only_87 \
	$(BUILD_DIR)/test_sign_verify_44 \
	$(BUILD_DIR)/test_sign_verify_65 \
	$(BUILD_DIR)/test_sign_verify_87

$(ALL_BINARIES): $(ALL_SOURCE)
	echo "$@"
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(INC) $^ -o $@

all: build

build: $(ALL_BINARIES)

run: $(ALL_BINARIES)
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_keygen_only_44
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_keygen_only_65
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_keygen_only_87
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_sign_only_44
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_sign_only_65
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_sign_only_87
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_verify_only_44
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_verify_only_65
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_verify_only_87
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_sign_verify_44
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_sign_verify_65
	$(EXEC_WRAPPER) ./$(BUILD_DIR)/test_sign_verify_87

clean:
	rm -rf $(BUILD_DIR)
