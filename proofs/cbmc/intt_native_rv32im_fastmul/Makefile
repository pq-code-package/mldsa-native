# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = intt_native_rv32im_fastmul_harness
PROOF_UID = intt_native_rv32im_fastmul

DEFINES += -DMLD_CONFIG_USE_NATIVE_BACKEND_ARITH
DEFINES += -DMLD_CONFIG_ARITH_BACKEND_FILE="\"$(SRCDIR)/mldsa/src/native/rv32im/fastmul.h\""
DEFINES += -DMLD_CHECK_APIS

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/poly.c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/native/rv32im/src/rv32im_zetas.c

CHECK_FUNCTION_CONTRACTS = mld_intt_native
USE_FUNCTION_CONTRACTS = mld_intt_rv32im_fastmul_asm
APPLY_LOOP_CONTRACTS = on
USE_DYNAMIC_FRAMES = 1

CBMC_SUPPORTED_CONFIGS = ILP32:z3 LP64:z3
CBMC_DEFAULT_CONFIG = ILP32:z3
CBMC_OBJECT_BITS = 8

FUNCTION_NAME = intt_native_rv32im_fastmul

include ../Makefile.common
