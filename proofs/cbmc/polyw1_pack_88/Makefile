# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

include ../Makefile_params.common

HARNESS_ENTRY = harness
HARNESS_FILE = polyw1_pack_88_harness

# This should be a unique identifier for this proof, and will appear on the
# Litani dashboard. It can be human-readable and contain spaces if you wish.
PROOF_UID = polyw1_pack_88

DEFINES +=
INCLUDES +=

REMOVE_FUNCTION_BODY +=
UNWINDSET +=

PROOF_SOURCES += $(PROOFDIR)/$(HARNESS_FILE).c
PROJECT_SOURCES += $(SRCDIR)/mldsa/src/poly.c

ifeq ($(MLD_CONFIG_PARAMETER_SET),44)
CHECK_FUNCTION_CONTRACTS=mld_polyw1_pack_88
else
CHECK_FUNCTION_CONTRACTS=
endif
USE_FUNCTION_CONTRACTS=
APPLY_LOOP_CONTRACTS=on
USE_DYNAMIC_FRAMES=1

# Disable any setting of EXTERNAL_SAT_SOLVER, and choose SMT backend instead
EXTERNAL_SAT_SOLVER=
CBMCFLAGS=--smt2

FUNCTION_NAME = polyw1_pack_88

# This function is large enough to need...
CBMC_OBJECT_BITS = 8

include ../Makefile.common
