# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = poly_accumulate_column_entry_harness
PROOF_UID = poly_accumulate_column_entry

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/polyvec_lazy.c

MLD_CONFIG_REDUCE_RAM = 1
MLD_CONFIG_REDUCE_RAM_X4 = 1
CHECK_FUNCTION_CONTRACTS=mld_poly_accumulate_column_entry
USE_FUNCTION_CONTRACTS=mld_poly_pointwise_montgomery
USE_FUNCTION_CONTRACTS+=mld_poly_add
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

CBMC_SUPPORTED_CONFIGS = \
  LP64:z3 \
  LP64:cadical
CBMC_DEFAULT_CONFIG = LP64:z3
CBMC_OBJECT_BITS = 9

include ../Makefile.common
