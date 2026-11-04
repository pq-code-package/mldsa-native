# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = polyvec_matrix_pointwise_montgomery_rows_tail_harness
PROOF_UID = polyvec_matrix_pointwise_montgomery_rows_tail

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/polyvec_lazy.c

MLD_CONFIG_REDUCE_RAM = 1
MLD_CONFIG_REDUCE_RAM_X4 = 1
CHECK_FUNCTION_CONTRACTS=mld_polyvec_matrix_pointwise_montgomery_rows
USE_FUNCTION_CONTRACTS=mld_polyvec_matrix_pointwise_montgomery_row
# The partial batch has at most three rows. Unwind it to avoid SAT's
# incomplete handling of the invariant's quantifier with symbolic bound j.
UNWINDSET += mld_polyvec_matrix_pointwise_montgomery_rows.1:4
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

CBMC_SUPPORTED_CONFIGS = \
  LP64:z3_no_bv_extract \
  LP64:cadical
CBMC_DEFAULT_CONFIG = LP64:z3_no_bv_extract
ifeq ($(MLD_CONFIG_PARAMETER_SET),87)
CBMC_OBJECT_BITS = 12
else
CBMC_OBJECT_BITS = 11
endif

include ../Makefile.common
