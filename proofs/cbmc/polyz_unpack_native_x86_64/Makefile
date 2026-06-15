# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = polyz_unpack_native_x86_64_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = polyz_unpack_native_x86_64

# We need to set MLD_CHECK_APIS as otherwise mldsa/src/native/api.h won't be
# included, which contains the CBMC specifications.
DEFINES += -DMLD_CONFIG_USE_NATIVE_BACKEND_ARITH -DMLD_CONFIG_ARITH_BACKEND_FILE="\"$(SRCDIR)/mldsa/src/native/x86_64/meta.h\"" -DMLD_CHECK_APIS
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/poly_kl.c

# polyz_unpack_17 is used with ML-DSA-44 (GAMMA1 = 2^17);
# polyz_unpack_19 with ML-DSA-65 and ML-DSA-87 (GAMMA1 = 2^19).
ifeq ($(MLD_CONFIG_PARAMETER_SET),44)
    CHECK_FUNCTION_CONTRACTS=mld_polyz_unpack_17_native
    USE_FUNCTION_CONTRACTS=mld_polyz_unpack_17_avx2_asm
else ifeq ($(MLD_CONFIG_PARAMETER_SET),65)
    CHECK_FUNCTION_CONTRACTS=mld_polyz_unpack_19_native
    USE_FUNCTION_CONTRACTS=mld_polyz_unpack_19_avx2_asm
else ifeq ($(MLD_CONFIG_PARAMETER_SET),87)
    CHECK_FUNCTION_CONTRACTS=mld_polyz_unpack_19_native
    USE_FUNCTION_CONTRACTS=mld_polyz_unpack_19_avx2_asm
endif
USE_FUNCTION_CONTRACTS+=mld_sys_check_capability
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

# Disable any setting of EXTERNAL_SAT_SOLVER, and choose SMT backend instead
EXTERNAL_SAT_SOLVER=
CBMCFLAGS=--smt2

FUNCTION_NAME = polyz_unpack_native_x86_64

# This function is large enough to need...
CBMC_OBJECT_BITS = 8

include ../Makefile.common
