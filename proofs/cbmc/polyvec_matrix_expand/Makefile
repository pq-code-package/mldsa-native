# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = polyvec_matrix_expand_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = polyvec_matrix_expand

DEFINES +=
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=
# For CaDiCaL, unroll the sampling loops instead of applying their loop
# contracts: with a symbolic loop index, the havoc of the sampled entries
# is at a symbolic offset into the matrix, which is very expensive for the
# propositional backend.
UNWINDSET += $(if $(filter cadical,$(CBMC_SOLVER)),mld_polyvec_matrix_expand_eager.1:4) # Inner loop over the 4 batched entries
UNWINDSET += $(if $(filter cadical,$(CBMC_SOLVER)),mld_polyvec_matrix_expand_eager.2:14) # Largest value of MLDSA_K * MLDSA_L / 4
UNWINDSET += $(if $(filter cadical,$(CBMC_SOLVER)),mld_polyvec_matrix_expand_eager.3:3) # Largest value of (MLDSA_K * MLDSA_L) % 4

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/polyvec_lazy.c

CHECK_FUNCTION_CONTRACTS=mld_polyvec_matrix_expand
ifdef MLD_CONFIG_REDUCE_RAM
USE_FUNCTION_CONTRACTS=
else
USE_FUNCTION_CONTRACTS=mld_poly_uniform_4x
USE_FUNCTION_CONTRACTS+=mld_poly_permute_bitrev_to_custom_optional
USE_FUNCTION_CONTRACTS+=mld_polymat_expand_entry
USE_FUNCTION_CONTRACTS+=mld_zeroize
endif
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

# Supported CBMC configurations
# With cadical, ML-DSA-87 runs out of resources in CI.
ifeq ($(MLD_CONFIG_PARAMETER_SET),87)
CBMC_SUPPORTED_CONFIGS = LP64:z3_no_bv_extract
else
CBMC_SUPPORTED_CONFIGS = \
  LP64:z3_no_bv_extract \
  LP64:cadical
endif
CBMC_DEFAULT_CONFIG = LP64:z3_no_bv_extract

FUNCTION_NAME = polyvec_matrix_expand

# If this proof is found to consume huge amounts of RAM, you can set the
# EXPENSIVE variable. With new enough versions of the proof tools, this will
# restrict the number of EXPENSIVE CBMC jobs running at once. See the
# documentation in Makefile.common under the "Job Pools" heading for details.
# EXPENSIVE = true

# This function is large enough to need...
CBMC_OBJECT_BITS = 12

# If you require access to a file-local ("static") function or object to conduct
# your proof, set the following (and do not include the original source file
# ("mldsa/poly.c") in PROJECT_SOURCES).
# REWRITTEN_SOURCES = $(PROOFDIR)/<__SOURCE_FILE_BASENAME__>.i
# include ../Makefile.common
# $(PROOFDIR)/<__SOURCE_FILE_BASENAME__>.i_SOURCE = $(SRCDIR)/mldsa/src/poly.c
# $(PROOFDIR)/<__SOURCE_FILE_BASENAME__>.i_FUNCTIONS = foo bar
# $(PROOFDIR)/<__SOURCE_FILE_BASENAME__>.i_OBJECTS = baz
# Care is required with variables on the left-hand side: REWRITTEN_SOURCES must
# be set before including Makefile.common, but any use of variables on the
# left-hand side requires those variables to be defined. Hence, _SOURCE,
# _FUNCTIONS, _OBJECTS is set after including Makefile.common.

include ../Makefile.common
