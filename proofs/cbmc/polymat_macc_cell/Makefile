# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = polymat_macc_cell_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = mld_polymat_macc_cell

# mld_polymat_macc_cell is only compiled in MLD_CONFIG_REDUCE_RAM mode.
MLD_CONFIG_REDUCE_RAM := 1

DEFINES +=
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/polyvec_lazy.c

CHECK_FUNCTION_CONTRACTS=mld_polymat_macc_cell
USE_FUNCTION_CONTRACTS=mld_polymat_expand_entry
USE_FUNCTION_CONTRACTS+=mld_poly_pointwise_montgomery
USE_FUNCTION_CONTRACTS+=mld_poly_add
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

# Disable any setting of EXTERNAL_SAT_SOLVER, and choose SMT backend instead
EXTERNAL_SAT_SOLVER=
CBMCFLAGS=--smt2

FUNCTION_NAME = mld_polymat_macc_cell

# If this proof is found to consume huge amounts of RAM, you can set the
# EXPENSIVE variable. With new enough versions of the proof tools, this will
# restrict the number of EXPENSIVE CBMC jobs running at once. See the
# documentation in Makefile.common under the "Job Pools" heading for details.
# EXPENSIVE = true

CBMC_OBJECT_BITS = 8

include ../Makefile.common
