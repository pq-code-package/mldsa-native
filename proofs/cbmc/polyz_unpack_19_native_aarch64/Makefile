# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = polyz_unpack_19_native_aarch64_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = polyz_unpack_19_native_aarch64

# We need to set MLD_CHECK_APIS as otherwise mldsa/src/native/api.h won't be
# included, which contains the CBMC specifications.
DEFINES += -DMLD_CONFIG_USE_NATIVE_BACKEND_ARITH -DMLD_CONFIG_ARITH_BACKEND_FILE="\"$(SRCDIR)/mldsa/src/native/aarch64/meta.h\"" -DMLD_CHECK_APIS
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/poly_kl.c $(SRCDIR)/mldsa/src/native/aarch64/src/polyz_unpack_table.c

# polyz_unpack_19 is only used with ML-DSA-65 and ML-DSA-87
ifeq ($(MLD_CONFIG_PARAMETER_SET),65)
CHECK_FUNCTION_CONTRACTS=mld_polyz_unpack_19_native
USE_FUNCTION_CONTRACTS = mld_polyz_unpack_19_aarch64_asm
else ifeq ($(MLD_CONFIG_PARAMETER_SET),87)
CHECK_FUNCTION_CONTRACTS=mld_polyz_unpack_19_native
USE_FUNCTION_CONTRACTS = mld_polyz_unpack_19_aarch64_asm
else
CHECK_FUNCTION_CONTRACTS=
USE_FUNCTION_CONTRACTS =
endif
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

FUNCTION_NAME = polyz_unpack_19_native_aarch64

# If this proof is found to consume huge amounts of RAM, you can set the
# EXPENSIVE variable. With new enough versions of the proof tools, this will
# restrict the number of EXPENSIVE CBMC jobs running at once. See the
# documentation in Makefile.common under the "Job Pools" heading for details.
# EXPENSIVE = true

# This function is large enough to need...
CBMC_OBJECT_BITS = 8

# If you require access to a file-local ("static") function or object to conduct
# your proof, set the following (and do not include the original source file
# ("mldsa/poly_kl.c") in PROJECT_SOURCES).
# REWRITTEN_SOURCES = $(PROOFDIR)/<__SOURCE_FILE_BASENAME__>.i
# include ../Makefile.common
# $(PROOFDIR)/<__SOURCE_FILE_BASENAME__>.i_SOURCE = $(SRCDIR)/mldsa/src/poly_kl.c
# $(PROOFDIR)/<__SOURCE_FILE_BASENAME__>.i_FUNCTIONS = foo bar
# $(PROOFDIR)/<__SOURCE_FILE_BASENAME__>.i_OBJECTS = baz
# Care is required with variables on the left-hand side: REWRITTEN_SOURCES must
# be set before including Makefile.common, but any use of variables on the
# left-hand side requires those variables to be defined. Hence, _SOURCE,
# _FUNCTIONS, _OBJECTS is set after including Makefile.common.

include ../Makefile.common
