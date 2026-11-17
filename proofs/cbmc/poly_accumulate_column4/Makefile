# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = poly_accumulate_column4_harness
PROOF_UID = poly_accumulate_column4

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/polyvec_lazy.c

MLD_CONFIG_REDUCE_RAM = 1
MLD_CONFIG_REDUCE_RAM_X4 = 1
CHECK_FUNCTION_CONTRACTS=mld_poly_accumulate_column4
USE_FUNCTION_CONTRACTS=mld_polymat_expand_column4
USE_FUNCTION_CONTRACTS+=mld_poly_accumulate_column_entry
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

CBMC_SUPPORTED_CONFIGS = \
  LP64:z3 \
  LP64:cadical
CBMC_DEFAULT_CONFIG = LP64:z3
CBMC_OBJECT_BITS = 11

include ../Makefile.common
