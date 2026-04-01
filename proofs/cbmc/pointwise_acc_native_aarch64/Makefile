# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = pointwise_acc_native_aarch64_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = pointwise_acc_native_aarch64

# We need to set MLD_CHECK_APIS as otherwise mldsa/src/native/api.h won't be
# included, which contains the CBMC specifications.
DEFINES += -DMLD_CONFIG_USE_NATIVE_BACKEND_ARITH -DMLD_CONFIG_ARITH_BACKEND_FILE="\"$(SRCDIR)/mldsa/src/native/aarch64/meta.h\"" -DMLD_CHECK_APIS
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/polyvec.c

ifeq ($(MLD_CONFIG_PARAMETER_SET),44)
    CHECK_FUNCTION_CONTRACTS=mld_polyvecl_pointwise_acc_montgomery_l4_native
    USE_FUNCTION_CONTRACTS=mld_polyvecl_pointwise_acc_montgomery_l4_asm
else ifeq ($(MLD_CONFIG_PARAMETER_SET),65)
    CHECK_FUNCTION_CONTRACTS=mld_polyvecl_pointwise_acc_montgomery_l5_native
    USE_FUNCTION_CONTRACTS=mld_polyvecl_pointwise_acc_montgomery_l5_asm
else ifeq ($(MLD_CONFIG_PARAMETER_SET),87)
    CHECK_FUNCTION_CONTRACTS=mld_polyvecl_pointwise_acc_montgomery_l7_native
    USE_FUNCTION_CONTRACTS=mld_polyvecl_pointwise_acc_montgomery_l7_asm
endif
USE_FUNCTION_CONTRACTS+=mld_sys_check_capability
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

# Disable any setting of EXTERNAL_SAT_SOLVER, and choose SMT backend instead
EXTERNAL_SAT_SOLVER=
CBMCFLAGS=--external-smt2-solver $(PROOF_ROOT)/lib/z3_smt_only --z3

FUNCTION_NAME = pointwise_acc_native_aarch64

# If this proof is found to consume huge amounts of RAM, you can set the
# EXPENSIVE variable. With new enough versions of the proof tools, this will
# restrict the number of EXPENSIVE CBMC jobs running at once. See the
# documentation in Makefile.common under the "Job Pools" heading for details.
# EXPENSIVE = true

# This function is large enough to need...
CBMC_OBJECT_BITS = 8

include ../Makefile.common
