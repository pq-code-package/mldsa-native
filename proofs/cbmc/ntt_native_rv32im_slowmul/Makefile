# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = ntt_native_rv32im_slowmul_harness
PROOF_UID = ntt_native_rv32im_slowmul

DEFINES += -DMLD_CONFIG_USE_NATIVE_BACKEND_ARITH
DEFINES += -DMLD_CONFIG_ARITH_BACKEND_FILE="\"$(SRCDIR)/mldsa/src/native/rv32im/slowmul.h\""
DEFINES += -DMLD_CHECK_APIS

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/poly.c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/native/rv32im/src/rv32im_zetas.c

CHECK_FUNCTION_CONTRACTS = mld_ntt_native
USE_FUNCTION_CONTRACTS = mld_ntt_rv32im_slowmul_asm
APPLY_LOOP_CONTRACTS = on
USE_DYNAMIC_FRAMES = 1

CBMC_SUPPORTED_CONFIGS = ILP32:z3 LP64:z3
CBMC_DEFAULT_CONFIG = ILP32:z3
CBMC_OBJECT_BITS = 8

FUNCTION_NAME = ntt_native_rv32im_slowmul

include ../Makefile.common
