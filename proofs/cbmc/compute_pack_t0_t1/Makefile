# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = compute_pack_t0_t1_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = compute_pack_t0_t1

DEFINES +=
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/sign.c

CHECK_FUNCTION_CONTRACTS=mld_compute_pack_t0_t1
USE_FUNCTION_CONTRACTS=mld_polyvec_matrix_pointwise_montgomery_row
USE_FUNCTION_CONTRACTS+=mld_poly_invntt_tomont
USE_FUNCTION_CONTRACTS+=mld_poly_add
USE_FUNCTION_CONTRACTS+=mld_poly_reduce
USE_FUNCTION_CONTRACTS+=mld_poly_caddq
USE_FUNCTION_CONTRACTS+=mld_poly_power2round
USE_FUNCTION_CONTRACTS+=mld_polyt1_pack
USE_FUNCTION_CONTRACTS+=mld_polyt0_pack
USE_FUNCTION_CONTRACTS+=mld_polyvec_matrix_expand
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

# To add or override per-solver entries in the solver matrix, set the
# variables below for each solver. {SOLVER} is one of the canonical
# solver identifiers (Z3, BITWUZLA, CVC5), declared in Makefile.common as
# CBMC_SOLVERS_ALL.
#
#     CBMC_SOLVER_{SOLVER}_ENABLED ?= 0/1
#     CBMC_SOLVER_{SOLVER}_FLAGS   ?= <extra CBMCFLAGS for {SOLVER}>
#     CBMC_SOLVER_{SOLVER}_EXT_SAT ?= <EXTERNAL_SAT_SOLVER for {SOLVER}>
#
# Solvers default to enabled; disable a solver explicitly by setting
# CBMC_SOLVER_{SOLVER}_ENABLED = 0. The per-harness CBMC_DEFAULT_SOLVER
# selects which enabled solver is used when the harness is invoked
# directly (`make report` from this directory). The driver
# run-cbmc-proofs.py overrides CBMC_SOLVER on the command line to fan
# out across all enabled solvers.
#
# Solver matrix
CBMC_DEFAULT_SOLVER          = Z3
CBMC_SOLVER_Z3_ENABLED       = 1
CBMC_SOLVER_Z3_FLAGS         = --external-smt2-solver $(PROOF_ROOT)/lib/z3_no_bv_extract --z3

FUNCTION_NAME = compute_pack_t0_t1

CBMC_OBJECT_BITS = 10

include ../Makefile.common
