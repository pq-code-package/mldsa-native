# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = polyvec_matrix_pointwise_montgomery_rows_harness
PROOF_UID = polyvec_matrix_pointwise_montgomery_rows

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/polyvec_lazy.c

CHECK_FUNCTION_CONTRACTS=mld_polyvec_matrix_pointwise_montgomery_rows
USE_FUNCTION_CONTRACTS=mld_polyvec_matrix_pointwise_montgomery_row
ifdef MLD_CONFIG_REDUCE_RAM_X4
USE_FUNCTION_CONTRACTS+=mld_poly_accumulate_column4
USE_FUNCTION_CONTRACTS+=mld_poly_reduce
# Unwind the unreachable tail too, so SAT never ignores its quantified invariant.
UNWINDSET += mld_polyvec_matrix_pointwise_montgomery_rows.1:4
endif
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

CBMC_SUPPORTED_CONFIGS = \
  LP64:z3_no_bv_extract \
  LP64:cadical
CBMC_DEFAULT_CONFIG = LP64:z3_no_bv_extract
CBMC_CONFIG_FLAGS = $(if $(filter cadical,$(CBMC_SOLVER)),,--arrays-uf-always)
ifeq ($(MLD_CONFIG_PARAMETER_SET),87)
CBMC_OBJECT_BITS = 12
else
CBMC_OBJECT_BITS = 11
endif
EXPENSIVE = true

include ../Makefile.common
