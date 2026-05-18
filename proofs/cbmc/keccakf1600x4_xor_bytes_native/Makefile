# Copyright (c) The mldsa-native project authors
# Copyright (c) The mlkem-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = keccakf1600x4_xor_bytes_native_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = keccakf1600x4_xor_bytes_native

DEFINES += -DMLD_CONFIG_USE_NATIVE_BACKEND_FIPS202 -DMLD_CONFIG_FIPS202_BACKEND_FILE="\"dummy_backend_fips202_x4.h\""
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/fips202/keccakf1600.c

CHECK_FUNCTION_CONTRACTS=mld_keccakf1600x4_xor_bytes
USE_FUNCTION_CONTRACTS=mld_keccakf1600_xor_bytes_x4_native mld_keccakf1600x4_xor_bytes_c
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
CBMC_DEFAULT_SOLVER          = BITWUZLA
CBMC_SOLVER_BITWUZLA_ENABLED = 1

FUNCTION_NAME = keccakf1600x4_xor_bytes_native

# This function is large enough to need...
CBMC_OBJECT_BITS = 8

include ../Makefile.common
