# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = polyveck_pointwise_poly_montgomery_s2_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = polyveck_pointwise_poly_montgomery_s2

DEFINES +=
INCLUDES +=

REMOVE_FUNCTION_BODY +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/sign.c

CHECK_FUNCTION_CONTRACTS=mld_polyveck_pointwise_poly_montgomery_s2
USE_FUNCTION_CONTRACTS=mld_poly_pointwise_montgomery
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

# Disable any setting of EXTERNAL_SAT_SOLVER, and choose SMT backend instead
EXTERNAL_SAT_SOLVER=
CBMCFLAGS=--smt2 --slice-formula

FUNCTION_NAME = polyveck_pointwise_poly_montgomery_s2

CBMC_OBJECT_BITS = 9

include ../Makefile.common
